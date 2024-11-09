
// favorite_poems_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:test_app/component/wallet_manager.dart';
import 'package:test_app/model.dart';
import 'package:test_app/state/fav_state.dart';
import 'package:test_app/state/poems.dart';
import 'package:test_app/widget/poem_card.dart';

class FavoritePoemsScreen extends StatefulWidget {
  @override
  _FavoritePoemsScreenState createState() => _FavoritePoemsScreenState();
}

class _FavoritePoemsScreenState extends State<FavoritePoemsScreen> with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  
  // Theme colors
  static const backgroundColor = Color(0xFF000000);
  static const surfaceColor = Color(0xFF121212);
  static const cardColor = Color(0xFF1E1E1E);
  static const accentColor = Color(0xFF6C63FF);

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _headerAnimation;

  @override
  void initState() {
    super.initState();
    
    // Initialize animations
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
    );

    _headerAnimation = CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
    );

    _animationController.forward();
    context.read<FavoritePoemsCubit>().loadFavoritePoems();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: backgroundColor,
        appBarTheme: const AppBarTheme(
          backgroundColor: backgroundColor,
          elevation: 0,
        ),
      ),
      child: BlocConsumer<FavoritePoemsCubit, FavoritePoemsState>(
        listener: (context, state) {
          if (state.error != null) {
            _showErrorSnackBar(state.error!);
          }
        },
        builder: (context, state) {
          return Scaffold(
            body: NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) => [
                _buildAppBar(innerBoxIsScrolled),
              ],
              body: _buildBody(state),
            ),
          );
        },
      ),
    );
  }

 Future<void> _handleReward(Poem poem, BigInt amount) async {
    try {
      // Check for private key
      final hasKey = await WalletManager.hasPrivateKey();
      
      if (!hasKey) {
        if (!mounted) return;
        // Show private key dialog
        final result = await showPrivateKeyDialog(context);
        if (result == null) {
          _showErrorSnackBar('Private key is required to reward poems');
          return;
        }
      }

      // Show loading overlay
      if (!mounted) return;
      _showRewardingOverlay();

      // Get private key and process reward
      final privateKey = await WalletManager.getPrivateKey();
      if (privateKey == null) throw Exception('Private key not found');

      await context.read<PoetryCubit>().rewardPoem(poem, amount , privateKey);

      // Hide loading overlay
      if (!mounted) return;
      Navigator.pop(context); // Remove loading overlay

      // Show success message
      _showSuccessSnackBar(
        'Reward sent successfully!',
        icon: Icons.stars_rounded,
        color: Colors.amber,
      );

    } catch (e) {
      // Hide loading overlay if showing
      if (mounted) Navigator.pop(context);
      _showErrorSnackBar(e.toString());
    }
  }
Future<String?> showPrivateKeyDialog(BuildContext context) {
  final controller = TextEditingController();
  bool obscureText = true;

  return showDialog<String>(
    context: context,
    builder: (context) => Theme(
      data: ThemeData.dark().copyWith(
        dialogBackgroundColor: cardColor,
      ),
      child: AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        contentPadding: const EdgeInsets.all(24),
        content: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.key_rounded,
                      color: accentColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text(
                      'Private Key Required',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'A private key is required to publish poems. This will be stored securely on your device.',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: accentColor.withOpacity(0.3),
                  ),
                ),
                child: TextField(
                  controller: controller,
                  obscureText: obscureText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'Lora',
                  ),
                  decoration: InputDecoration(
                    hintText: 'Enter your private key',
                    hintStyle: TextStyle(
                      color: Colors.white.withOpacity(0.3),
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(16),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureText
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: Colors.white.withOpacity(0.5),
                      ),
                      onPressed: () {
                        setState(() => obscureText = !obscureText);
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          accentColor,
                          accentColor.withOpacity(0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: accentColor.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () async {
                          final key = controller.text.trim();
                          if (key.isNotEmpty) {
                            await WalletManager.savePrivateKey(key);
                            Navigator.pop(context, key);
                          }
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          child: const Text(
                            'Continue',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

  void _showRewardingOverlay() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
        onWillPop: () async => false,
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            margin: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Animated icon
                TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 1500),
                  tween: Tween(begin: 0.0, end: 1.0),
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: 0.8 + (0.2 * value),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.stars_rounded,
                          size: 32,
                          color: Colors.amber.withOpacity(value),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
                const Text(
                  'Processing Reward',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'Please wait while we process your transaction...',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                // Loading indicator
                TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 1500),
                  tween: Tween(begin: 0.0, end: 1.0),
                  builder: (context, value, child) {
                    return CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color.lerp(
                          accentColor.withOpacity(0.5),
                          accentColor,
                          value,
                        )!,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Update the success snackbar method
  void _showSuccessSnackBar(
    String message, {
    IconData icon = Icons.check_circle_outline_rounded,
    Color color = Colors.green,
    String? txHash,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      color: color,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      message,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              if (txHash != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      'Transaction: ',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 12,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        txHash,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      iconSize: 16,
                      icon: const Icon(Icons.copy),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: txHash));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                Icon(
                                  Icons.check_rounded,
                                  color: Colors.white,
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                const Text('Transaction hash copied'),
                              ],
                            ),
                            duration: const Duration(seconds: 1),
                            backgroundColor: cardColor,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        backgroundColor: cardColor,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: color.withOpacity(0.3),
          ),
        ),
      ),
    );
  }

  // Update the poems list to use the new reward handler
  Widget _buildPoemsList(FavoritePoemsState state) {
    return RefreshIndicator(
      onRefresh: () => context.read<FavoritePoemsCubit>().loadFavoritePoems(),
      color: accentColor,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        itemCount: state.favoritePoems.length,
        itemBuilder: (context, index) {
          final poem = state.favoritePoems[index];
          return TweenAnimationBuilder<double>(
            duration: Duration(milliseconds: 400 + (index * 100)),
            curve: Curves.easeOutQuart,
            tween: Tween(begin: 0.0, end: 1.0),
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(0, 50 * (1 - value)),
                child: Opacity(
                  opacity: value,
                  child: child,
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: AnimatedPoemCard(
                isFavorite: true,
                key: ValueKey(poem.id),
                poem: poem,
                onLike: () => context.read<PoetryCubit>().likePoem(poem),
                onReward: (amount) => _handleReward(poem, amount), // Updated
                onFollow: () => context.read<PoetryCubit>().addFollower(poem),
                addToFavorites: (poem) => context.read<PoetryCubit>().removeFormFavorites(poem),
              ),
            ),
          );
        },
      ),
    );
  }
  Widget _buildAppBar(bool innerBoxIsScrolled) {
    return SliverAppBar(
      expandedHeight: 120,
      pinned: true,
      stretch: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        title: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.3),
            end: Offset.zero,
          ).animate(_headerAnimation),
          child: const Text(
            'Favorite Poems',
            style: TextStyle(
              fontFamily: 'Lora',
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                accentColor.withOpacity(0.2),
                backgroundColor,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(FavoritePoemsState state) {
    if (state.status == FavoritePoemsStatus.loading && state.favoritePoems.isEmpty) {
      return _buildLoadingState();
    }

    if (state.status == FavoritePoemsStatus.failure && state.favoritePoems.isEmpty) {
      return _buildErrorState(state.error);
    }

    if (state.favoritePoems.isEmpty) {
      return _buildEmptyState();
    }

    return _buildPoemsList(state);
  }

  Widget _buildLoadingState() {
    return Center(
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 1500),
              tween: Tween(begin: 0.0, end: 1.0),
              builder: (context, value, child) {
                return Transform.scale(
                  scale: 0.8 + (0.2 * value),
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      accentColor.withOpacity(value),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            Text(
              'Loading your favorites...',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String? error) {
    return Center(
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 800),
              tween: Tween(begin: 0.0, end: 1.0),
              builder: (context, value, child) {
                return Transform.rotate(
                  angle: (1 - value) * 2 * 3.14159,
                  child: Icon(
                    Icons.error_outline_rounded,
                    size: 64,
                    color: Colors.red.withOpacity(value),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            Text(
              error ?? 'Something went wrong',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                context.read<FavoritePoemsCubit>().loadFavoritePoems();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 1200),
              tween: Tween(begin: 0.0, end: 1.0),
              builder: (context, value, child) {
                return Transform.scale(
                  scale: 0.8 + (0.2 * value),
                  child: Icon(
                    Icons.favorite_outline_rounded,
                    size: 80,
                    color: Colors.red.withOpacity(0.5),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            const Text(
              'No favorites yet',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Start adding poems you love!',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }



  void _showErrorSnackBar(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Icon(
                Icons.error_outline_rounded,
                color: Colors.red[300],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: surfaceColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: Colors.red.withOpacity(0.3),
          ),
        ),
      ),
    );
  }
}