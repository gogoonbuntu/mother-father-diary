import 'package:flutter/material.dart';

class PrivacyInfoScreen extends StatelessWidget {
  const PrivacyInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🔒 데이터 보호'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green.shade400, Colors.teal.shade500],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Column(
                children: [
                  Icon(Icons.shield_rounded, size: 48, color: Colors.white),
                  SizedBox(height: 12),
                  Text(
                    '당신의 일기는\n안전하게 보호됩니다',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1.3,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '종단간 암호화(E2EE) 적용',
                    style: TextStyle(fontSize: 14, color: Colors.white70),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 암호화 방식
            _buildInfoCard(
              icon: Icons.lock_rounded,
              iconColor: Colors.blue.shade600,
              title: '어떻게 암호화되나요?',
              children: const [
                _BulletPoint('일기 내용은 기기에서 AES-256 군사급 암호화로 변환됩니다'),
                _BulletPoint('암호화된 상태로 서버에 저장되므로, 서버에서는 깨진 문자만 보입니다'),
                _BulletPoint('개발자를 포함한 그 누구도 내용을 확인할 수 없습니다'),
              ],
            ),

            const SizedBox(height: 16),

            // 키 보호
            _buildInfoCard(
              icon: Icons.vpn_key_rounded,
              iconColor: Colors.orange.shade600,
              title: '암호화 키는 어떻게 보호되나요?',
              children: const [
                _BulletPoint('암호화 키는 Google 계정 정보로부터 자동 생성됩니다'),
                _BulletPoint('키는 기기 메모리에만 존재하며, 어디에도 저장되지 않습니다'),
                _BulletPoint('같은 Google 계정으로 로그인하면 항상 같은 키가 생성됩니다'),
              ],
            ),

            const SizedBox(height: 16),

            // 걱정하지 않아도 되는 것
            _buildInfoCard(
              icon: Icons.check_circle_rounded,
              iconColor: Colors.green.shade600,
              title: '안심하세요',
              children: const [
                _BulletPoint('📱 기기를 바꿔도 → 같은 Google 계정이면 복원 가능'),
                _BulletPoint('🗑️ 앱을 삭제해도 → 재설치 후 로그인하면 복원 가능'),
                _BulletPoint('🔄 여러 기기 사용해도 → 같은 계정이면 어디서든 열람 가능'),
              ],
            ),

            const SizedBox(height: 16),

            // 주의사항
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Colors.amber.shade700, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        '꼭 기억해주세요',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber.shade800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Google 계정을 삭제하면 암호화 키를 재생성할 수 없어 '
                    '일기 내용을 복구할 수 없습니다. Google 계정을 안전하게 유지해주세요.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.amber.shade900,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 기술 스펙
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '기술 사양',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildSpecRow('암호화 알고리즘', 'AES-256-CBC'),
                  _buildSpecRow('키 파생', 'SHA-256 (2회 해싱)'),
                  _buildSpecRow('IV 생성', 'MD5 (일기별 고유값)'),
                  _buildSpecRow('데이터 식별', 'E2E: 접두사'),
                ],
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  static Widget _buildInfoCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  static Widget _buildSpecRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
          Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey.shade800)),
        ],
      ),
    );
  }
}

class _BulletPoint extends StatelessWidget {
  final String text;
  const _BulletPoint(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 6, right: 8),
            child: Icon(Icons.circle, size: 6, color: Colors.grey),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14, height: 1.5, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}
