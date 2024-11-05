import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:test_app/create_poem.dart';
import 'package:test_app/model.dart';
import 'package:test_app/profile_screen.dart';
import 'package:test_app/screens/my_poems.dart';
import 'package:test_app/search.dart';
import 'package:test_app/state/poems.dart';
import 'package:test_app/state/reward_screen.dart';
import 'package:test_app/widget/poem_card.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}
class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(_handleTabChange);
    _scrollController.addListener(_handleScroll);
    context.read<PoetryCubit>().loadInitialPoems(_tabController.index);
    context.read<PoetryCubit>().getFollowedPoems();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
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

  List<Poem> _getCurrentPoems(PoetryState state) {
    switch (_tabController.index) {
      case 0:
        return state.forYouPoems;
      case 1:
        return state.followingPoems;
      case 2:
        return state.trendingPoems;
      case 3:
        return state.newPoems;
      case 4:
        return state.followingPoems;
      default:
        return [];
    }
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
        return Scaffold(
          body: IndexedStack(
            index: _currentIndex,
            children: [
              _buildMainFeed(state),
              AuthorPoemsScreen(),
              RewardsScreen(),
            ],
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: (index) {
              setState(() => _currentIndex = index);
              HapticFeedback.selectionClick();
            },
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person),
                label: 'Profile',
              ),
              NavigationDestination(
                icon: Icon(Icons.card_giftcard),
                selectedIcon: Icon(Icons.person),
                label: 'Rewards',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMainFeed(PoetryState state) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Poetry Feed',
          style: TextStyle(
            fontFamily: 'Lora',
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _showSearch(context),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'For You'),
            Tab(text: 'Following'),
            Tab(text: 'Trending'),
            Tab(text: 'New'),
            Tab(text: 'Followed'),
          ],
        ),
      ),
      body: _buildBody(state),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => CreatePoemScreen()),
          ).then((_) => context.read<PoetryCubit>().loadInitialPoems(_tabController.index));
        },
        child: const Icon(Icons.add),
        tooltip: 'Create Poem',
      ),
    );
  }

Widget _buildBody(PoetryState state) {
  // Check if initial loading
  if (state.status == PoetryStatus.loading && _getCurrentPoems(state).isEmpty) {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  // Check for error state
  if (state.status == PoetryStatus.failure && _getCurrentPoems(state).isEmpty) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            state.error ?? 'An error occurred',
            style: const TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => context.read<PoetryCubit>().loadInitialPoems(_tabController.index),
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  final poems = _getCurrentPoems(state);
  if (poems.isEmpty) {
    if (_tabController.index == 4) {
      // Show "No followed poems" message if the user is on the Followed tab
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.sentiment_dissatisfied_outlined, size: 48, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No followed poems',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    } else {
      // Show default empty state for other tabs
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.note_outlined, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'No poems found',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => context.read<PoetryCubit>().loadInitialPoems(_tabController.index),
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
            ),
          ],
        ),
      );
    }
  }

  return RefreshIndicator(
    onRefresh: () => context.read<PoetryCubit>().loadInitialPoems(_tabController.index),
    child: ListView.builder(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: poems.length + (state.hasMorePoems ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == poems.length) {
          return Visibility(
            visible: state.status == PoetryStatus.loading,
            child: const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            ),
          );
        }

        final poem = poems[index];
        return AnimatedPoemCard(
          key: ValueKey(poem.id),
          poem: poem,
          onLike: () => context.read<PoetryCubit>().likePoem(poem),
          onReward: (amount) => context.read<PoetryCubit>().rewardPoem(poem, amount),
          onFollow: () => context.read<PoetryCubit>().addFollower(poem),
        );
      },
    ),
  );
}

  void _showSearch(BuildContext context) {
    showSearch(
      context: context,
      delegate: PoemSearchDelegate(),
    );
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: CustomSnackBar(
          message: message,
          icon: Icons.error_outline,
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
    );
  }
}