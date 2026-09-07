using System;
using System.Collections.Generic;
using System.Linq;

namespace PortKiller.Models;

/// <summary>
/// Filter settings for the port list
/// </summary>
public class PortFilter
{
    public string SearchText { get; set; } = string.Empty;
    public int? MinPort { get; set; }
    public int? MaxPort { get; set; }
    public HashSet<ProcessType> ProcessTypes { get; set; } = new(Enum.GetValues<ProcessType>());
    public bool ShowOnlyFavorites { get; set; }
    public bool ShowOnlyWatched { get; set; }

    public bool IsActive =>
        !string.IsNullOrEmpty(SearchText) ||
        MinPort.HasValue ||
        MaxPort.HasValue ||
        ProcessTypes.Count < Enum.GetValues<ProcessType>().Length ||
        ShowOnlyFavorites ||
        ShowOnlyWatched;

    public bool Matches(PortInfo port, HashSet<int> favorites, List<WatchedPort> watched)
    {
        // Search text filter
        if (!string.IsNullOrEmpty(SearchText))
        {
            var query = SearchText.ToLowerInvariant();
            var matches = port.ProcessName.ToLowerInvariant().Contains(query) ||
                         port.Port.ToString().Contains(query) ||
                         port.Pid.ToString().Contains(query) ||
                         port.Address.ToLowerInvariant().Contains(query) ||
                         port.User.ToLowerInvariant().Contains(query) ||
                         port.Command.ToLowerInvariant().Contains(query);
            if (!matches) return false;
        }

        // Port range filter
        if (MinPort.HasValue && port.Port < MinPort.Value) return false;
        if (MaxPort.HasValue && port.Port > MaxPort.Value) return false;

        // Process type filter
        if (!ProcessTypes.Contains(port.ProcessType)) return false;

        // Favorites filter
        if (ShowOnlyFavorites && !favorites.Contains(port.Port)) return false;

        // Watched filter
        if (ShowOnlyWatched && !watched.Any(w => w.Port == port.Port)) return false;

        return true;
    }

    public void Reset()
    {
        SearchText = string.Empty;
        MinPort = null;
        MaxPort = null;
        ProcessTypes = new(Enum.GetValues<ProcessType>());
        ShowOnlyFavorites = false;
        ShowOnlyWatched = false;
    }
}

/// <summary>
/// Sidebar navigation items
/// </summary>
public enum SidebarItem
{
    AllPorts,
    Favorites,
    Watched,
    WebServer,
    Database,
    Development,
    System,
    Other,
    KubernetesPortForward,
    CloudflareTunnels,
    Settings
}

public static class SidebarItemExtensions
{
    public static string GetTitle(this SidebarItem item) => item switch
    {
        SidebarItem.AllPorts => "全部端口",
        SidebarItem.Favorites => "收藏",
        SidebarItem.Watched => "关注端口",
        SidebarItem.WebServer => "Web 服务器",
        SidebarItem.Database => "数据库",
        SidebarItem.Development => "开发",
        SidebarItem.System => "系统",
        SidebarItem.Other => "其他",
        SidebarItem.KubernetesPortForward => "K8s 端口转发",
        SidebarItem.CloudflareTunnels => "Cloudflare 隧道",
        SidebarItem.Settings => "设置",
        _ => "未知"
    };

    public static string GetIcon(this SidebarItem item) => item switch
    {
        SidebarItem.AllPorts => "\uE8FD", // List
        SidebarItem.Favorites => "\uE734", // Favorite
        SidebarItem.Watched => "\uE890", // View
        SidebarItem.WebServer => "\uE774", // Globe
        SidebarItem.Database => "\uF1AA", // Database
        SidebarItem.Development => "\uE90F", // Code
        SidebarItem.System => "\uE713", // Settings
        SidebarItem.Other => "\uE7E8", // Plug
        SidebarItem.KubernetesPortForward => "\uE968", // Connect
        SidebarItem.CloudflareTunnels => "\uE753", // Cloud
        SidebarItem.Settings => "\uE713", // Settings
        _ => "\uE7E8"
    };

    public static ProcessType? GetProcessType(this SidebarItem item) => item switch
    {
        SidebarItem.WebServer => ProcessType.WebServer,
        SidebarItem.Database => ProcessType.Database,
        SidebarItem.Development => ProcessType.Development,
        SidebarItem.System => ProcessType.System,
        SidebarItem.Other => ProcessType.Other,
        _ => null
    };
}
