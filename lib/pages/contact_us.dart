import 'package:flutter/material.dart';

class ContactUsPage extends StatelessWidget {
  const ContactUsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'You can get in touch with us through below platform. '
                  'Our team will reach out to you as soon as it would be possible',
              style: TextStyle(
                fontSize: 14,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 20),

            /// CUSTOMER SUPPORT
            _buildCard(
              title: 'Customer Support',
              child: Column(
                children: const [
                  _InfoRow(
                    icon: Icons.phone,
                    label: 'Contact Number',
                    value: '+62 81311201808',
                  ),
                  SizedBox(height: 16),
                  _InfoRow(
                    icon: Icons.email,
                    label: 'Email Address',
                    value: 'help@zapp.com',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            /// SOCIAL MEDIA
            _buildCard(
              title: 'Social Media',
              child: Column(
                children: const [
                  _SocialRow(
                    assetPath: 'assets/icon/instagram.png',
                    label: 'Instagram',
                    username: '@zappID',
                  ),
                  SizedBox(height: 16),
                  _SocialRow(
                    assetPath: 'assets/icon/twitter.png',
                    label: 'X',
                    username: '@zappID',
                  ),
                  SizedBox(height: 16),
                  _SocialRow(
                    assetPath: 'assets/icon/telegram.png',
                    label: 'Telegram',
                    username: '@zappID',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// CARD CONTAINER
  static Widget _buildCard({
    required String title,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

/// INFO ROW (PHONE & EMAIL)
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: Colors.grey.shade200,
          child: Icon(
            icon,
            color: Colors.grey.shade700,
            size: 18,
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// SOCIAL MEDIA ROW (ASSET IMAGE)
class _SocialRow extends StatelessWidget {
  final String assetPath;
  final String label;
  final String username;

  const _SocialRow({
    required this.assetPath,
    required this.label,
    required this.username,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Image.asset(
          assetPath,
          width: 36,
          height: 36,
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              username,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
