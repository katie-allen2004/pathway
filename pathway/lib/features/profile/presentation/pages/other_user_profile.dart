import 'package:flutter/material.dart';
import 'package:pathway/core/widgets/widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '/features/auth/data/report_user.dart';

class OtherUserProfilePage extends StatelessWidget {
  final String userId;
  final String displayName;

  final VoidCallback? onMessage;

  const OtherUserProfilePage({
    super.key,
    required this.userId,
    required this.displayName,
    this.onMessage,
  });

  @override
  Widget build(BuildContext context) {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    final bool isViewingOwnProfile = userId == currentUserId;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5), 
      appBar: PathwayAppBar(
        height: 80,
        title: const Text("User Profile"),
        centertitle: true,
        automaticallyImplyLeading: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _ProfileHeader(displayName: displayName),
            const SizedBox(height: 30), 
            
            _IdentitySection(displayName: displayName),
            const SizedBox(height: 24),

            if (!isViewingOwnProfile) ...[
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: onMessage, // ✅ calls back into ConversationsPage
                    icon: const Icon(Icons.chat_bubble_outline_rounded, size: 20),
                    label: const Text("Message"),
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
            
            _buildInfoCard(
              icon: Icons.info_outline,
              title: "About",
              content: "This is a verified Pathway student profile. Reach out to start a conversation about accessible venues!",
            ),
            const SizedBox(height: 12),
            
            _buildInfoCard(
              icon: Icons.history,
              title: "Activity",
              content: "No recent reviews or posts to display at this time.",
            ),
            const SizedBox(height: 12), 

            if (!isViewingOwnProfile) 
               _ModerationTools(userId: userId, displayName: displayName),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({required IconData icon, required String title, required String content}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16), 
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02), 
              blurRadius: 5, 
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.deepPurple, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                  const SizedBox(height: 4),
                  Text(content, style: const TextStyle(color: Colors.black54, height: 1.4)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final String displayName;
  const _ProfileHeader({required this.displayName});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xFFF0F2F5), 
      padding: const EdgeInsets.only(top: 40),
      child: Center(
        child: CircleAvatar(
          radius: 50,
          backgroundColor: Colors.white,
          child: CircleAvatar(
            radius: 46,
            backgroundColor: Colors.grey.shade200,
            child: const Icon(Icons.person, size: 50, color: Colors.grey),
          ),
        ),
      ),
    );
  }
}

class _IdentitySection extends StatelessWidget {
  final String displayName;
  const _IdentitySection({required this.displayName});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          displayName,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const Text(
          "Pathway Verified User",
          style: TextStyle(color: Colors.grey, letterSpacing: 0.5),
        ),
      ],
    );
  }
}

class _ModerationTools extends StatelessWidget {
  final String userId;
  final String displayName;
  const _ModerationTools({required this.userId, required this.displayName});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 5, 
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Column(
          children: [
            const Icon(Icons.gpp_maybe_outlined, color: Colors.redAccent, size: 28),
            const SizedBox(height: 12),
            const Text(
              "Community Safety", 
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            const Text(
              "Is this user violating community standards? Let us know to keep the community safe.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () => _triggerReportFlow(context),
                icon: const Icon(Icons.flag_outlined, size: 20),
                label: Text("Report $displayName"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade50,
                  foregroundColor: Colors.red,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _triggerReportFlow(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => ReportUserDialog(reportedUserId: userId),
    );
  }
}