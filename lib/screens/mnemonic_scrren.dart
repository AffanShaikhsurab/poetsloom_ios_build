import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:test_app/home.dart';
import 'package:test_app/services/mnemonic.dart';

class MnemonicGenerationScreen extends StatefulWidget {
  final String encryptionKey;
  final VoidCallback onComplete;

  const MnemonicGenerationScreen({
    Key? key,
    required this.encryptionKey,
    required this.onComplete,
  }) : super(key: key);

  @override
  State<MnemonicGenerationScreen> createState() => _MnemonicGenerationScreenState();
}

class _MnemonicGenerationScreenState extends State<MnemonicGenerationScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _showMnemonic = false;
  bool _keysCopied = false;
  String? _mnemonic;
  bool _isLoading = true;
  String? _error;
  String ? mnemonic;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1500),
    );
    _generateMnemonic();
  }

  Future<void> _generateMnemonic() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Assuming MnemonicService is your service class for mnemonic operations
      final mnemonicService = MnemonicService(baseUrl: 'https://poetsloom-mnemonic.onrender.com');
      final generatedMnemonic = await mnemonicService.keyToMnemonic(widget.encryptionKey);
      mnemonic = generatedMnemonic["mnemonic"];
      if (mounted) {
        setState(() {
          _mnemonic = generatedMnemonic["mnemonic"];
          _isLoading = false;
        });

        // Start animation when mnemonic is generated
        _controller.forward();
        Future.delayed(Duration(milliseconds: 1500), () {
          if (mounted) {
            setState(() => _showMnemonic = true);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to generate mnemonic: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveMnemonicAndProceed() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      if (_mnemonic != null && mnemonic!.isNotEmpty) {
        await prefs.setString('mnemonic', _mnemonic!);
        print("the saved mnemonic is $_mnemonic");
        if (mounted) {
   Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => HomeScreen()),
              );          
              // widget.onComplete();
        }
      } else {
        _showError('Mnemonic not generated');
      }
    } catch (e) {
      _showError('Error saving mnemonic: ${e.toString()}');
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  void _copyToClipboard(String value, String label) {
    Clipboard.setData(ClipboardData(text: value));
    setState(() => _keysCopied = true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label copied to clipboard')),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.fromARGB(255, 0, 6, 20),
                Color.fromARGB(255, 15, 23, 42),
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                ShaderMask(
                  shaderCallback: (Rect bounds) {
                    return const LinearGradient(
                      colors: [
                        Color.fromARGB(255, 99, 102, 241),
                        Color.fromARGB(255, 168, 85, 247),
                      ],
                    ).createShader(bounds);
                  },
                  child: const Text(
                    'Backup Keys',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Store these keys safely. You\'ll need them to recover your account.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white60,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                if (_error != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.red.withOpacity(0.2),
                      ),
                    ),
                    child: Text(
                      _error!,
                      style: TextStyle(
                        color: Colors.red.shade300,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                if (_isLoading || !_showMnemonic)
                  Container(
                    height: 120,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Center(
                      child: SizedBox(
                        width: 80,
                        height: 80,
                        child: Lottie.asset(
                          'assets/loading.json',
                          controller: _controller,
                          onLoaded: (composition) {
                            _controller
                              ..duration = composition.duration
                              ..forward();
                          },
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _BuildKeyCard(
                          title: 'Encryption Key',
                          value: widget.encryptionKey,
                          onCopy: () => _copyToClipboard(
                            widget.encryptionKey,
                            'Key',
                          ),
                        ),
                        const SizedBox(height: 24),
                        _BuildKeyCard(
                          title: 'Recovery Phrase',
                          value: _mnemonic ?? '',
                          onCopy: () => _copyToClipboard(
                            _mnemonic ?? '',
                            'Mnemonic',
                          ),
                        ),
                      ],
                    ),
                  ),
                if (_showMnemonic) ...[
                  const SizedBox(height: 32),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: _keysCopied
                          ? const LinearGradient(
                              colors: [
                                Color.fromARGB(255, 99, 102, 241),
                                Color.fromARGB(255, 168, 85, 247),
                              ],
                            )
                          : null,
                      color: _keysCopied
                          ? null
                          : const Color.fromARGB(255, 30, 41, 59),
                    ),
                    child: ElevatedButton(
                      onPressed: _keysCopied ? _saveMnemonicAndProceed : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'I\'ve Saved My Keys',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Please copy both keys before proceeding',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Update the key card design
class _BuildKeyCard extends StatelessWidget {
  final String title;
  final String value;
  final VoidCallback onCopy;

  const _BuildKeyCard({
    required this.title,
    required this.value,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color.fromARGB(255, 99, 102, 241).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.copy,
                    color: Colors.white.withOpacity(0.7),
                    size: 20,
                  ),
                  onPressed: onCopy,
                ),
              ],
            ),
            const SizedBox(height: 8),
            SelectableText(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
      ),
    );
  }
}