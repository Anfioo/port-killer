using System.Collections.ObjectModel;
using System.ComponentModel;
using System.Diagnostics;
using System.Runtime.CompilerServices;
using System.Windows;
using System.Windows.Threading;
using PortKiller.Models;
using PortKiller.Services;

namespace PortKiller.ViewModels;

/// <summary>
/// ViewModel for managing Cloudflare tunnels
/// </summary>
public class TunnelViewModel : INotifyPropertyChanged
{
    private readonly TunnelService _tunnelService;
    private readonly NotificationService _notificationService;
    private readonly SettingsService _settings;
    private readonly DispatcherTimer _uptimeTimer;
    private bool _isCloudflaredInstalled;
    private CloudflaredProtocol _cloudflaredProtocol;

    public ObservableCollection<CloudflareTunnel> Tunnels { get; }
    public IReadOnlyList<CloudflaredProtocolOption> ProtocolOptions { get; }

    public bool IsCloudflaredInstalled
    {
        get => _isCloudflaredInstalled;
        set => SetField(ref _isCloudflaredInstalled, value);
    }

    public int ActiveTunnelCount => Tunnels.Count(t => t.Status == TunnelStatus.Active);

    public CloudflaredProtocol CloudflaredProtocol
    {
        get => _cloudflaredProtocol;
        set
        {
            if (SetField(ref _cloudflaredProtocol, value))
            {
                _settings.SaveCloudflaredProtocol(value);
            }
        }
    }

    public TunnelViewModel(TunnelService tunnelService, NotificationService notificationService, SettingsService settings)
    {
        _tunnelService = tunnelService;
        _notificationService = notificationService;
        _settings = settings;
        Tunnels = new ObservableCollection<CloudflareTunnel>();
        ProtocolOptions = new List<CloudflaredProtocolOption>
        {
            new(CloudflaredProtocol.Http2, "HTTP/2"),
            new(CloudflaredProtocol.Quic, "QUIC")
        };

        // Check if cloudflared is installed
        IsCloudflaredInstalled = _tunnelService.IsCloudflaredInstalled;
        CloudflaredProtocol = _settings.GetCloudflaredProtocol();

        // Set up timer to update uptime every second
        _uptimeTimer = new DispatcherTimer
        {
            Interval = TimeSpan.FromSeconds(1)
        };
        _uptimeTimer.Tick += (s, e) => UpdateUptimes();
        _uptimeTimer.Start();

        // Clean up orphaned tunnels from previous sessions
        Task.Run(async () => await _tunnelService.CleanupOrphanedTunnelsAsync());
    }

    /// <summary>
    /// Starts a new tunnel for the specified port
    /// </summary>
    public async Task StartTunnelAsync(int port)
    {
        if (!IsCloudflaredInstalled)
        {
            MessageBox.Show(
                "cloudflared 未安装。请安装后以使用 Cloudflare 隧道。\n\n" +
                "安装方式：\n" +
                "1. 下载地址：https://github.com/cloudflare/cloudflared/releases\n" +
                "2. 或使用 Chocolatey：choco install cloudflared",
                "cloudflared 未找到",
                MessageBoxButton.OK,
                MessageBoxImage.Warning);
            return;
        }

        // Check if tunnel already exists for this port
        var existingTunnel = Tunnels.FirstOrDefault(t => t.Port == port && t.Status != TunnelStatus.Error);
        if (existingTunnel != null)
        {
            // Already tunneling this port - just copy the URL if available
            if (!string.IsNullOrEmpty(existingTunnel.TunnelUrl))
            {
                CopyUrlToClipboard(existingTunnel.TunnelUrl);
            }
            return;
        }

        var tunnel = new CloudflareTunnel(port)
        {
            Status = TunnelStatus.Starting
        };

        Application.Current.Dispatcher.Invoke(() => Tunnels.Add(tunnel));

        // Set up handlers
        _tunnelService.SetUrlHandler(tunnel.Id, url =>
        {
            Application.Current.Dispatcher.Invoke(() =>
            {
                tunnel.TunnelUrl = url;
                tunnel.Status = TunnelStatus.Active;
                tunnel.StartTime = DateTime.Now;

                // Auto-copy URL to clipboard
                CopyUrlToClipboard(url);

                // Send notification
                _notificationService.Notify(
                    "隧道已激活",
                    $"端口 {tunnel.Port} 现已公开，地址：\n{ShortenUrl(url)}");

                OnPropertyChanged(nameof(ActiveTunnelCount));
            });
        });

        _tunnelService.SetErrorHandler(tunnel.Id, error =>
        {
            Application.Current.Dispatcher.Invoke(() =>
            {
                tunnel.LastError = error;
                if (tunnel.Status != TunnelStatus.Active)
                {
                    tunnel.Status = TunnelStatus.Error;
                }
                Debug.WriteLine($"Tunnel error: {error}");
            });
        });

        try
        {
            await _tunnelService.StartTunnelAsync(tunnel, CloudflaredProtocol);

            // Wait a bit to see if URL is detected
            await Task.Delay(3000);

            if (tunnel.Status == TunnelStatus.Starting)
            {
                // Still starting, URL should appear soon
                Debug.WriteLine($"Tunnel for port {port} is starting, waiting for URL...");
            }
        }
        catch (Exception ex)
        {
            Application.Current.Dispatcher.Invoke(() =>
            {
                tunnel.Status = TunnelStatus.Error;
                tunnel.LastError = ex.Message;
                
                MessageBox.Show(
                    $"启动端口 {port} 的隧道失败：\n{ex.Message}",
                    "隧道错误",
                    MessageBoxButton.OK,
                    MessageBoxImage.Error);
            });
        }
    }

    /// <summary>
    /// Stops a tunnel
    /// </summary>
    public async Task StopTunnelAsync(CloudflareTunnel tunnel)
    {
        tunnel.Status = TunnelStatus.Stopping;

        try
        {
            await _tunnelService.StopTunnelAsync(tunnel.Id);
            
            Application.Current.Dispatcher.Invoke(() =>
            {
                Tunnels.Remove(tunnel);
                OnPropertyChanged(nameof(ActiveTunnelCount));
            });
        }
        catch (Exception ex)
        {
            Debug.WriteLine($"Error stopping tunnel: {ex.Message}");
            tunnel.Status = TunnelStatus.Error;
            tunnel.LastError = ex.Message;
        }
    }

    /// <summary>
    /// Stops all active tunnels
    /// </summary>
    public async Task StopAllTunnelsAsync()
    {
        var tunnelsToStop = Tunnels.ToList();
        
        foreach (var tunnel in tunnelsToStop)
        {
            tunnel.Status = TunnelStatus.Stopping;
        }

        await _tunnelService.StopAllTunnelsAsync();

        Application.Current.Dispatcher.Invoke(() =>
        {
            Tunnels.Clear();
            OnPropertyChanged(nameof(ActiveTunnelCount));
        });
    }

    /// <summary>
    /// Copies tunnel URL to clipboard
    /// </summary>
    public void CopyUrlToClipboard(string url)
    {
        try
        {
            Clipboard.SetText(url);
            _notificationService.Notify("已复制", "隧道 URL 已复制到剪贴板");
        }
        catch (Exception ex)
        {
            Debug.WriteLine($"Failed to copy to clipboard: {ex.Message}");
        }
    }

    /// <summary>
    /// Opens tunnel URL in default browser
    /// </summary>
    public void OpenUrlInBrowser(string url)
    {
        try
        {
            Process.Start(new ProcessStartInfo
            {
                FileName = url,
                UseShellExecute = true
            });
        }
        catch (Exception ex)
        {
            MessageBox.Show(
                $"打开 URL 失败：\n{ex.Message}",
                "错误",
                MessageBoxButton.OK,
                MessageBoxImage.Error);
        }
    }

    /// <summary>
    /// Re-checks cloudflared installation status
    /// </summary>
    public void RecheckInstallation()
    {
        IsCloudflaredInstalled = _tunnelService.IsCloudflaredInstalled;
    }

    /// <summary>
    /// Updates uptime for all active tunnels
    /// </summary>
    private void UpdateUptimes()
    {
        foreach (var tunnel in Tunnels.Where(t => t.Status == TunnelStatus.Active))
        {
            // Trigger property change for uptime
            tunnel.OnPropertyChanged(nameof(tunnel.Uptime));
        }
    }

    /// <summary>
    /// Shortens a trycloudflare.com URL for display
    /// </summary>
    private string ShortenUrl(string url)
    {
        return url.Replace("https://", "");
    }

    // INotifyPropertyChanged implementation
    public event PropertyChangedEventHandler? PropertyChanged;

    protected virtual void OnPropertyChanged([CallerMemberName] string? propertyName = null)
    {
        PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(propertyName));
    }

    protected bool SetField<T>(ref T field, T value, [CallerMemberName] string? propertyName = null)
    {
        if (EqualityComparer<T>.Default.Equals(field, value)) return false;
        field = value;
        OnPropertyChanged(propertyName);
        return true;
    }
}

public sealed class CloudflaredProtocolOption
{
    public CloudflaredProtocolOption(CloudflaredProtocol value, string label)
    {
        Value = value;
        Label = label;
    }

    public CloudflaredProtocol Value { get; }
    public string Label { get; }
}
