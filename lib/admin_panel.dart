import 'package:flutter/material.dart';
import 'package:unihub/tabs/admin_requests_tab.dart';
import 'package:unihub/tabs/admin_events_tab.dart';
import 'package:unihub/tabs/admin_members_tab.dart';
import 'package:unihub/tabs/admin_settings_tab.dart';

class AdminPanel extends StatefulWidget {
  final String kulupId;
  final String kulupismi;
  final Color primaryColor;
  final String currentUserRole;
  final bool isSuperAdmin; // YENİ

  const AdminPanel({
    super.key,
    required this.kulupId,
    required this.kulupismi,
    required this.primaryColor,
    required this.currentUserRole,
    this.isSuperAdmin = false, // Varsayılan false
  });

  @override
  State<AdminPanel> createState() => _AdminPanelState();
}

class _AdminPanelState extends State<AdminPanel> with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _setupTabsByRole();
  }

  void _setupTabsByRole() {
    List<Widget> tabs = [
      const Tab(icon: Icon(Icons.person_add), text: "İstekler"),
    ];

    if (widget.currentUserRole != 'uye') {
      tabs.add(const Tab(icon: Icon(Icons.event), text: "Etkinlikler"));
    }

    if (widget.currentUserRole == 'baskan') {
      tabs.add(const Tab(icon: Icon(Icons.people), text: "Üyeler"));
      tabs.add(const Tab(icon: Icon(Icons.settings), text: "Ayarlar"));
    }

    _tabController = TabController(length: tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: widget.primaryColor,
        title: Text(
          "${widget.kulupismi} Yönetimi",
          style: const TextStyle(color: Colors.white, fontSize: 18),
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: _getTabs(),
        ),
      ),
      body: TabBarView(controller: _tabController, children: _getTabViews()),
    );
  }

  List<Widget> _getTabs() {
    List<Widget> tabs = [
      const Tab(icon: Icon(Icons.person_add), text: "İstekler"),
    ];
    if (widget.currentUserRole != 'uye') {
      tabs.add(const Tab(icon: Icon(Icons.event), text: "Etkinlikler"));
    }
    if (widget.currentUserRole == 'baskan') {
      tabs.add(const Tab(icon: Icon(Icons.people), text: "Üyeler"));
      tabs.add(const Tab(icon: Icon(Icons.settings), text: "Ayarlar"));
    }
    return tabs;
  }

  List<Widget> _getTabViews() {
    List<Widget> views = [AdminRequestsTab(kulupId: widget.kulupId)];

    if (widget.currentUserRole != 'uye') {
      views.add(AdminEventsTab(kulupId: widget.kulupId));
    }

    if (widget.currentUserRole == 'baskan') {
      // isSuperAdmin bilgisini buraya iletiyoruz 👇
      views.add(
        AdminMembersTab(
          kulupId: widget.kulupId,
          currentUserRole: widget.currentUserRole,
          isSuperAdmin: widget.isSuperAdmin,
        ),
      );
      views.add(
        AdminSettingsTab(
          kulupId: widget.kulupId,
          primaryColor: widget.primaryColor,
        ),
      );
    }
    return views;
  }
}
