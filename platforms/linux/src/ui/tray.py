import sys
import threading
import gi
gi.require_version('Gtk', '3.0')
from gi.repository import Gtk, GLib

# Import AppIndicator/AyatanaAppIndicator
try:
    gi.require_version('AppIndicator3', '0.1')
    from gi.repository import AppIndicator3 as appindicator
except (ValueError, ImportError):
    try:
        gi.require_version('AyatanaAppIndicator3', '0.1')
        from gi.repository import AyatanaAppIndicator3 as appindicator
    except (ValueError, ImportError):
        print("Error: AppIndicator3 or AyatanaAppIndicator3 is required.")
        sys.exit(1)

from .dialogs import PortDetailsDialog
from .window import MenuBarWindow
from ..scanner import PortScanner
from ..services.cloudflare import cloudflare_service
from ..services.k8s import k8s_service
from ..services.clipboard import copy_to_clipboard, notify

APPINDICATOR_ID = 'portkiller'

class PortKillerTrayApp:
    def __init__(self):
        # Locate AppIcon.svg
        from ..config import get_icon_path
        icon_path = get_icon_path()
        if not icon_path:
            icon_path = "utilities-system-monitor"  # Fallback system icon

        self.indicator = appindicator.Indicator.new(
            APPINDICATOR_ID,
            icon_path,
            appindicator.IndicatorCategory.SYSTEM_SERVICES
        )
        self.indicator.set_status(appindicator.IndicatorStatus.ACTIVE)

        self.menu = Gtk.Menu()
        self.indicator.set_menu(self.menu)

        # Cache variables to detect changes and prevent menu flickering/autoclose
        self.last_state = None

        # Searchable browser window, created on first use
        self.window = None

        # Build initial tray menu
        self.refresh_and_build()

        # Set up auto-refresh timer (every 5 seconds)
        GLib.timeout_add_seconds(5, self.auto_refresh)

    @staticmethod
    def _collect_state():
        """
        Run the system scans. Spawns several subprocesses, so this must never
        run on the GTK main thread.
        """
        ports = PortScanner.scan_ports()
        k8s_forwards = k8s_service.scan_active_forwards()

        # Get cloudflare tunnels
        cf_tunnels = list(cloudflare_service.active_tunnels.values())
        external_cf = cloudflare_service.scan_running_tunnels_from_ps()
        for ext in external_cf:
            if not any(
                (t.port if hasattr(t, 'port') else t.get('port', 0)) == ext['port']
                for t in cf_tunnels
            ):
                cf_tunnels.append(ext)

        return ports, k8s_forwards, cf_tunnels

    def refresh_and_build(self):
        # Scan off the main thread, then rebuild the menu back on it.
        def worker():
            try:
                ports, k8s_forwards, cf_tunnels = self._collect_state()
            except Exception as e:
                print(f"Error refreshing port data: {e}")
                return

            def apply():
                self.build_menu_with_data(ports, k8s_forwards, cf_tunnels)
                return False

            GLib.idle_add(apply)

        threading.Thread(target=worker, daemon=True).start()

    def build_menu_with_data(self, ports, k8s_forwards, cf_tunnels):
        # Clear previous items
        for child in self.menu.get_children():
            self.menu.remove(child)

        # 1. Cloudflare Tunnels Submenu
        cf_label = f"☁️ Cloudflare 隧道 ({len(cf_tunnels)})"
        cf_item = Gtk.MenuItem(label=cf_label)
        cf_submenu = Gtk.Menu()
        cf_item.set_submenu(cf_submenu)
        
        if not cf_tunnels:
            no_cf = Gtk.MenuItem(label="无活动隧道")
            no_cf.set_sensitive(False)
            cf_submenu.append(no_cf)
        else:
            for t in cf_tunnels:
                port_val = t.port if hasattr(t, 'port') else t.get('port', 0)
                url_val = t.url if hasattr(t, 'url') else t.get('url', '')
                t_label = f"端口 {port_val} → {url_val if url_val else '启动中...'}"
                
                # Single tunnel options submenu
                single_t_item = Gtk.MenuItem(label=t_label)
                single_t_submenu = Gtk.Menu()
                single_t_item.set_submenu(single_t_submenu)
                
                if url_val:
                    copy_url_item = Gtk.MenuItem(label="📋 复制隧道 URL")
                    copy_url_item.connect("activate", lambda w, u=url_val: self.copy_and_notify(u, "隧道 URL 已复制到剪贴板！"))
                    single_t_submenu.append(copy_url_item)
                
                stop_tunnel_item = Gtk.MenuItem(label="💀 停止隧道")
                stop_tunnel_item.connect("activate", lambda w, p=port_val: self.stop_cf_tunnel_and_notify(p))
                single_t_submenu.append(stop_tunnel_item)
                
                cf_submenu.append(single_t_item)
        self.menu.append(cf_item)

        # 2. K8s Port Forwards Submenu
        k8s_label = f"☸️ K8s 端口转发 ({len(k8s_forwards)})"
        k8s_item = Gtk.MenuItem(label=k8s_label)
        k8s_submenu = Gtk.Menu()
        k8s_item.set_submenu(k8s_submenu)
        
        if not k8s_forwards:
            no_k8s = Gtk.MenuItem(label="无活动端口转发")
            no_k8s.set_sensitive(False)
            k8s_submenu.append(no_k8s)
        else:
            for k in k8s_forwards:
                k_label = f"{k.resource} → {k.local_port}:{k.remote_port} ({k.namespace})"
                
                # Single k8s options submenu
                single_k_item = Gtk.MenuItem(label=k_label)
                single_k_submenu = Gtk.Menu()
                single_k_item.set_submenu(single_k_submenu)
                
                copy_port_item = Gtk.MenuItem(label="📋 复制本地端口")
                copy_port_item.connect("activate", lambda w, p=k.local_port: self.copy_and_notify(str(p), f"端口 {p} 已复制到剪贴板！"))
                single_k_submenu.append(copy_port_item)
                
                stop_forward_item = Gtk.MenuItem(label="💀 停止端口转发")
                stop_forward_item.connect("activate", lambda w, p=k.pid, r=k.resource: self.stop_k8s_forward_and_notify(p, r))
                single_k_submenu.append(stop_forward_item)
                
                k8s_submenu.append(single_k_item)
        self.menu.append(k8s_item)

        # 3. Local Ports Submenu (Restored direct clicks to open management Dialog)
        local_label = f"🌐 本地端口 ({len(ports)})"
        local_item = Gtk.MenuItem(label=local_label)
        local_submenu = Gtk.Menu()
        local_item.set_submenu(local_submenu)
        
        if not ports:
            no_ports = Gtk.MenuItem(label="无开放端口")
            no_ports.set_sensitive(False)
            local_submenu.append(no_ports)
        else:
            for p in ports:
                port_label = f"{p['port']} → {p['process_name']}"
                if p['pid'] != 0:
                    port_label += f" (PID {p['pid']})"
                
                # Port item clicking opens the Dialog modal
                port_item = Gtk.MenuItem(label=port_label)
                port_item.connect("activate", lambda w, port_info=p: self.open_port_dialog(port_info))
                local_submenu.append(port_item)
        self.menu.append(local_item)

        self.menu.append(Gtk.SeparatorMenuItem())

        # Item 4: Open the searchable port browser window
        window_item = Gtk.MenuItem(label="打开 PortKiller 窗口")
        window_item.connect("activate", lambda w: self.open_main_window())
        self.menu.append(window_item)

        # Item 5: Refresh Data
        refresh_item = Gtk.MenuItem(label="立即刷新")
        refresh_item.connect("activate", lambda w: self.refresh_and_build())
        self.menu.append(refresh_item)

        # Item 6: Quit
        quit_item = Gtk.MenuItem(label="退出 PortKiller")
        quit_item.connect("activate", lambda w: self.quit())
        self.menu.append(quit_item)

        self.menu.show_all()

    def open_main_window(self):
        # Created lazily and reused so window state (search, expanded rows)
        # survives between openings.
        if self.window is None:
            self.window = MenuBarWindow()
        self.window.show_near_pointer()

    def quit(self):
        # Tear down any tunnels we own so cloudflared children are not orphaned
        cloudflare_service.stop_all()
        Gtk.main_quit()

    def open_port_dialog(self, p):
        # Open port details dialog
        dialog = PortDetailsDialog(None, p)
        response = dialog.run()
        
        if response == 1:  # Kill Process (SIGTERM)
            if PortScanner.kill_process(p['pid'], force=False):
                notify("进程已结束", f"端口 {p['port']} 上的进程已结束 (SIGTERM)。")
            else:
                notify("结束失败", f"无法结束端口 {p['port']} 上的 PID {p['pid']}。")
        elif response == 2:  # Force Kill (SIGKILL)
            if PortScanner.kill_process(p['pid'], force=True):
                notify("进程已强制结束", f"端口 {p['port']} 上的进程已被强制结束 (SIGKILL)。")
            else:
                notify("结束失败", f"无法强制结束端口 {p['port']} 上的 PID {p['pid']}。")
        elif response == 3:  # Copy PID
            self.copy_and_notify(str(p['pid']), f"PID {p['pid']} 已复制到剪贴板！")
        elif response == 4:  # Copy Port
            self.copy_and_notify(str(p['port']), f"端口 {p['port']} 已复制到剪贴板！")
            
        dialog.destroy()
        # Refresh lists soon after closing/killing
        GLib.timeout_add(200, self.refresh_and_build)

    def copy_and_notify(self, text, message):
        copy_to_clipboard(text)
        notify("操作完成", message)

    def stop_cf_tunnel_and_notify(self, port):
        cloudflare_service.stop_tunnel(port)
        notify("隧道已停止", f"端口 {port} 上的 Cloudflare 隧道已停止！")
        GLib.timeout_add(200, self.refresh_and_build)

    def stop_k8s_forward_and_notify(self, pid, resource):
        if k8s_service.stop_port_forward(pid):
            notify("端口转发已停止", f"{resource} 的 Kubernetes 端口转发已停止！")
        else:
            notify("端口转发停止失败", f"无法停止 {resource} 的端口转发 (PID {pid})。")
        GLib.timeout_add(200, self.refresh_and_build)

    def auto_refresh(self):
        # Scan off the main thread so the tray stays responsive.
        def worker():
            try:
                ports, k8s_forwards, cf_tunnels = self._collect_state()
            except Exception as e:
                print(f"Error during auto-refresh: {e}")
                return

            # Hash/Represent current state to compare with previous state
            current_state = {
                'ports': [(p['port'], p['pid'], p['process_name']) for p in ports],
                'k8s': [(k.pid, k.local_port, k.remote_port, k.resource) for k in k8s_forwards],
                'cf': [(t.port if hasattr(t, 'port') else t.get('port', 0),
                        t.url if hasattr(t, 'url') else t.get('url', '')) for t in cf_tunnels]
            }

            def apply():
                # Rebuild only if something changed (prevents the menu from
                # closing while the user is reading it)
                if self.last_state != current_state:
                    self.last_state = current_state
                    self.build_menu_with_data(ports, k8s_forwards, cf_tunnels)
                return False

            GLib.idle_add(apply)

        threading.Thread(target=worker, daemon=True).start()
        return True
