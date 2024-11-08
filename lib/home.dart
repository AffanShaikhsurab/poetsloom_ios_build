import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import 'package:test_app/create_poem.dart';
import 'package:test_app/model.dart';
import 'package:test_app/screens/explore_screen.dart';
import 'package:test_app/screens/profile_screen.dart';
import 'package:test_app/state/poems.dart';
import 'package:test_app/state/reward_screen.dart';
import 'package:test_app/widget/poem_card.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();
  int _currentIndex = 0;

  // Theme colors
  static const backgroundColor = Color(0xFF000000);
  static const surfaceColor = Color(0xFF121212);
  static const accentColor = Color(0xFF6C63FF);
  static const cardColor = Color(0xFF1E1E1E);

  // Animation controllers
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    // Initialize tab controller
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabChange);
    
    // Initialize scroll controller
    _scrollController.addListener(_handleScroll);
    
    // Initialize fade animation
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
    
    // Initialize scale animation
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _scaleAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeOutBack,
    );
    
    // Start animations
    _fadeController.forward();
    _scaleController.forward();
    
    // Load initial data
    context.read<PoetryCubit>().loadInitialPoems(_tabController.index);
    context.read<PoetryCubit>().getFollowedPoems();

    // Set system UI style
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: backgroundColor,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PoetryCubit, PoetryState>(
      listener: (context, state) {
        if (state.error != null) {
          _showErrorSnackBar(state.error!);
        }
      },
      builder: (context, state) {
        return Theme(
          data: ThemeData.dark().copyWith(
            scaffoldBackgroundColor: backgroundColor,
            appBarTheme: const AppBarTheme(
              backgroundColor: backgroundColor,
              elevation: 0,
            ),
          ),
          child: Scaffold(
            body: IndexedStack(
              index: _currentIndex,
              children: [
                _buildMainFeed(state),
                ExploreScreen(),
                RewardsScreen(),
                PoetProfileScreen(),
              ],
            ),
            bottomNavigationBar: _buildBottomNav(),
            floatingActionButton: _buildFloatingActionButton(),
            floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
          ),
        );
      },
    );
  }

  Widget _buildMainFeed(PoetryState state) {
    return NestedScrollView(
      headerSliverBuilder: (context, innerBoxIsScrolled) => [
        SliverAppBar(
          floating: true,
          pinned: true,
          elevation: 0,
          backgroundColor: backgroundColor,
          expandedHeight: 120,
          flexibleSpace: FlexibleSpaceBar(
            title: FadeTransition(
              opacity: _fadeAnimation,
             child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                
                Padding(padding: EdgeInsets.fromLTRB(0,40, 50, 0)
                ,
                child: 
                Text(
                  'Poetry Feed',
                  style: TextStyle(
                    fontFamily: 'Lora',
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 24,
                  ),
                )),
                const SizedBox(height: 8),
              ],
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
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: accentColor,
            indicatorSize: TabBarIndicatorSize.label,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            tabs: [
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.local_fire_department, size: 20),
                    const SizedBox(width: 8),
                    const Text('For You'),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.people_outline, size: 20),
                    const SizedBox(width: 8),
                    const Text('Following'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
      body: _buildBody(state),
    );
  }

  Widget _buildBody(PoetryState state) {
    if (state.status == PoetryStatus.loading && _getCurrentPoems(state).isEmpty) {
      return _buildLoadingState();
    }

    if (state.status == PoetryStatus.failure && _getCurrentPoems(state).isEmpty) {
      return _buildErrorState(state.error ?? 'An error occurred');
    }

    final poems = _getCurrentPoems(state);
    if (poems.isEmpty) {
      return _buildEmptyState();
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: RefreshIndicator(
        color: accentColor,
        backgroundColor: cardColor,
        onRefresh: () => context.read<PoetryCubit>().loadInitialPoems(_tabController.index),
        child: ListView.builder(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(),
          itemCount: poems.length + (state.hasMorePoems ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == poems.length) {
              return _buildLoadingIndicator();
            }

            // Add stagger effect to list items
            return TweenAnimationBuilder<double>(
              duration: Duration(milliseconds: 500 + (index * 100)),
              curve: Curves.easeOutQuart,
              tween: Tween(begin: 50.0, end: 0.0),
              builder: (context, value, child) {
                return Transform.translate(
                  offset: Offset(0, value),
                  child: Opacity(
                    opacity: 1 - (value / 50),
                    child: child,
                  ),
                );
              },
              child: AnimatedPoemCard(
                key: ValueKey(poems[index].id),
                poem: poems[index],
                isFavorite: true,
                onLike: () => context.read<PoetryCubit>().likePoem(poems[index]),
                onReward: (amount) => context.read<PoetryCubit>().rewardPoem(poems[index], amount),
                onFollow: () => context.read<PoetryCubit>().addFollower(poems[index]),
                addToFavorites: (poem) => context.read<PoetryCubit>().addToFavorites(poem),
              ),
            );
          },
        ),
      ),
    );
  }


  Widget _buildBottomNav() {
    return NavigationBar(
      backgroundColor: surfaceColor,
      elevation: 0,
      height: 65,
      selectedIndex: _currentIndex,
      onDestinationSelected: (index) {
        setState(() => _currentIndex = index);
        HapticFeedback.selectionClick();
      },
      destinations: [
        _buildNavDestination(Icons.home_outlined, Icons.home, 'Home', 0),
        _buildNavDestination(Icons.search_outlined, Icons.search, 'Explore', 1),
        _buildNavDestination(Icons.card_giftcard_outlined, Icons.card_giftcard, 'Rewards', 2),
        _buildNavDestination(Icons.person_outline, Icons.person, 'Profile', 3),
      ],
    );
  }

  Widget _buildNavDestination(IconData icon, IconData selectedIcon, String label, int index) {
    final isSelected = _currentIndex == index;
    return NavigationDestination(
      icon: TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 300),
        tween: Tween(begin: 0.8, end: isSelected ? 1.0 : 0.8),
        builder: (context, value, child) {
          return Transform.scale(
            scale: value,
            child: Icon(
              isSelected ? selectedIcon : icon,
              color: isSelected ? accentColor : Colors.white60,
            ),
          );
        },
      ),
      label: label,
    );
  }

  Widget _buildFloatingActionButton() {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 300),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: child,
        );
      },
      child: FloatingActionButton(
        onPressed: () {
          HapticFeedback.mediumImpact();
          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) => CreatePoemScreen(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                const begin = Offset(0.0, 1.0);
                const end = Offset.zero;
                const curve = Curves.easeOutCubic;
                var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                var offsetAnimation = animation.drive(tween);
                return SlideTransition(position: offsetAnimation, child: child);
              },
            ),
          ).then((_) => context.read<PoetryCubit>().loadInitialPoems(_tabController.index));
        },
        backgroundColor: accentColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }


  List<Poem> _getCurrentPoems(PoetryState state) {
    return _tabController.index == 0 ? state.forYouPoems : state.followingPoems;
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging) {
      context.read<PoetryCubit>().loadInitialPoems(_tabController.index);
    }
  }

  void _handleScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      context.read<PoetryCubit>().loadMorePoems(_tabController.index);
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isDarkMode ? surfaceColor : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).colorScheme.error,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.error_outline,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
    );
  }
Widget _buildErrorState(String message) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 800),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Opacity(
            opacity: value,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Animated error icon
                    TweenAnimationBuilder<double>(
                      duration: const Duration(milliseconds: 1200),
                      tween: Tween(begin: 0.0, end: 1.0),
                      builder: (context, value, child) {
                        return Transform.rotate(
                          angle: (1 - value) * 1.8,
                          child: Icon(
                            Icons.error_outline_rounded,
                            size: 64,
                            color: Color.lerp(
                              Colors.red.withOpacity(0.5),
                              Colors.red,
                              value,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    // Error message
                    Text(
                      message,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    // Retry button
                    TweenAnimationBuilder<double>(
                      duration: const Duration(milliseconds: 600),
                      tween: Tween(begin: 0.0, end: 1.0),
                      builder: (context, value, child) {
                        return Transform.scale(
                          scale: 0.8 + (0.2 * value),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              gradient: LinearGradient(
                                colors: [
                                  accentColor.withOpacity(0.8),
                                  accentColor,
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: accentColor.withOpacity(0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: () {
                                HapticFeedback.mediumImpact();
                                context.read<PoetryCubit>().loadInitialPoems(_tabController.index);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                foregroundColor: Colors.white,
                                shadowColor: Colors.transparent,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 32,
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.refresh_rounded),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Try Again',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
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
      },
    );
  }

  Widget _buildEmptyState() {
    final isFollowingTab = _tabController.index == 1;
    
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 800),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.8 + (0.2 * value),
          child: Opacity(
            opacity: value,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Animated illustration
                    TweenAnimationBuilder<double>(
                      duration: const Duration(milliseconds: 1500),
                      tween: Tween(begin: 0.0, end: 1.0),
                      builder: (context, value, child) {
                        return Transform.scale(
                          scale: 1.0 + (0.1 * sin(value * 3 * 3.14159)),
                          child: Icon(
                            isFollowingTab 
                                ? Icons.people_outline_rounded
                                : Icons.article_outlined,
                            size: 80,
                            color: Color.lerp(
                              Colors.white24,
                              Colors.white38,
                              value,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    // Empty state message
                    Text(
                      isFollowingTab
                          ? 'No followed poems yet'
                          : 'No poems found',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      isFollowingTab
                          ? 'Start following poets to see their work here'
                          : 'Check back soon for new poems',
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (!isFollowingTab) ...[
                      const SizedBox(height: 32),
                      // Refresh button
                      TweenAnimationBuilder<double>(
                        duration: const Duration(milliseconds: 600),
                        tween: Tween(begin: 0.0, end: 1.0),
                        builder: (context, value, child) {
                          return Opacity(
                            opacity: value,
                            child: TextButton.icon(
                              onPressed: () {
                                HapticFeedback.mediumImpact();
                                context.read<PoetryCubit>().loadInitialPoems(_tabController.index);
                              },
                              icon: const Icon(Icons.refresh_rounded),
                              label: const Text('Refresh'),
                              style: TextButton.styleFrom(
                                foregroundColor: accentColor,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadingState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Animated loading indicator
        TweenAnimationBuilder<double>(
          duration: const Duration(seconds: 2),
          tween: Tween(begin: 0.0, end: 1.0),
          builder: (context, value, child) {
            return Transform.scale(
              scale: 0.8 + (0.2 * value),
              child: Container(
                width: 80,
                height: 80,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: accentColor.withOpacity(0.15),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Color.lerp(
                      accentColor.withOpacity(0.5),
                      accentColor,
                      value,
                    )!,
                  ),
                  strokeWidth: 3,
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 32),
        // Loading text
        TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 800),
          tween: Tween(begin: 0.0, end: 1.0),
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: const Column(
                children: [
                  Text(
                    'Loading Poetry',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Gathering the finest verses...',
                    style: TextStyle(
                      color: Colors.white60,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 48),
        // Loading progress dots
        TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 1500),
          tween: Tween(begin: 0.0, end: 1.0),
          builder: (context, value, child) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (index) {
                final delay = (index * 0.3);
                final opacity = sin((value * 3.14159 * 2) + delay);
                return Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.3 + (0.7 * opacity)),
                    shape: BoxShape.circle,
                  ),
                );
              }),
            );
          },
        ),
      ],
    );
  }

  Widget _buildLoadingIndicator() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 1000),
            tween: Tween(begin: 0.0, end: 1.0),
            builder: (context, value, child) {
              return Transform.scale(
                scale: 0.8 + (0.2 * value),
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Color.lerp(
                      accentColor.withOpacity(0.5),
                      accentColor,
                      value,
                    )!,
                  ),
                  strokeWidth: 2,
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 800),
            tween: Tween(begin: 0.0, end: 1.0),
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: const Text(
                  'Loading more poems...',
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 14,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}