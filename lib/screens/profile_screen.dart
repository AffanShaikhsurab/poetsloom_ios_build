import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:test_app/authservice.dart' as auth;
import 'package:test_app/create_poem.dart';
import 'package:test_app/screens/fav_poems.dart';
import 'package:test_app/screens/my_poems.dart';
import 'dart:math' as math;
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';


import 'package:test_app/screens/private_key.dart';
import 'package:test_app/screens/edit.dart';
import 'package:test_app/state/edit_state.dart';
class User {
  final String id;
  final String username;
  final String author_name;
  final String? profile; // Make profile nullable

  User({
    required this.id,
    required this.username,
    required this.author_name,
    this.profile,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      author_name: json['author_name']?.toString() ?? '',
      profile: json['profile']?.toString(),
    );
  }
}

// The
class PoetProfileScreen extends StatefulWidget {
  const PoetProfileScreen({Key? key}) : super(key: key);

  @override
  State<PoetProfileScreen> createState() => _PoetProfileScreenState();
}

class _PoetProfileScreenState extends State<PoetProfileScreen> with TickerProviderStateMixin {
  User? userData;
  bool isLoading = true;
  int user_followers = 0;
  int user_following = 0;
  int totalPoems = 0;
  // Theme colors
  static const backgroundColor = Color(0xFF000000);
  static const surfaceColor = Color(0xFF121212);
  static const cardColor = Color(0xFF1E1E1E);
  static const accentColor = Color(0xFF6C63FF);

  // Animation controllers
  late AnimationController _profileController;
  late AnimationController _menuController;
  late Animation<double> _profileScaleAnimation;
  late Animation<double> _profileFadeAnimation;
  late Animation<double> _menuSlideAnimation;

  @override
  void initState() {
    super.initState();
    
    // Initialize profile animations
    _profileController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _profileScaleAnimation = CurvedAnimation(
      parent: _profileController,
      curve: Curves.easeOutBack,
    );

    _profileFadeAnimation = CurvedAnimation(
      parent: _profileController,
      curve: Curves.easeOut,
    );

    // Initialize menu animations
    _menuController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _menuSlideAnimation = CurvedAnimation(
      parent: _menuController,
      curve: Curves.easeOutCubic,
    );

    loadUserData().then((_) {
      _profileController.forward();
      _menuController.forward();
    });
  }

  Future<void> loadUserData() async {
  try {
    final _prefs = await SharedPreferences.getInstance();
    final userDataString = _prefs.getString("user_data");
    
    if (userDataString == null) {
      setState(() {
        isLoading = false;
        userData = null;
      });
      return;
    }

    final jsonData = json.decode(userDataString);
    final id = jsonData["id"];
    
    // Set user data
    setState(() {
      userData = User.fromJson(jsonData);
    });

    // Supabase client
    final _supabase = SupabaseClient(
      'https://tfxbcnluzthdrwhtrntb.supabase.co',
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRmeGJjbmx1enRoZHJ3aHRybnRiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzA0NjI2NjksImV4cCI6MjA0NjAzODY2OX0.at0R_6S9vUk666sS1xJA_2jIoRLez_YN2PBLo_822vM'
    );

    // Get followers
    final followersRes = await _supabase
        .from("following")
        .select("*")
        .eq("authorId", int.parse(id.toString()));

    // Get following
    final followingRes = await _supabase
        .from("following")
        .select("*")
        .eq("userId", int.parse(id.toString()));

    // Get total poems
    final poemsRes = await _supabase
        .from("poems")
        .select("*")
        .eq("userId", int.parse(id.toString()));

    setState(() {
      user_followers = followersRes.length;
      user_following = followingRes.length;
      totalPoems = poemsRes.length;
      isLoading = false;  // Set loading to false after all data is loaded
    });

  } catch (e) {
    print('Error loading user data: $e');
    setState(() {
      isLoading = false;
      userData = null;
    });
    throw Exception('Failed to load user data: ${e.toString()}');
  }
}

  @override
  void dispose() {
    _profileController.dispose();
    _menuController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: backgroundColor,
      ),
      child: Scaffold(
        body: isLoading 
          ? _buildLoadingState()
          : userData == null 
            ? _buildErrorState()
            : _buildMainContent(),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 1500),
        tween: Tween(begin: 0.0, end: 1.0),
        builder: (context, value, child) {
          return Transform.scale(
            scale: 0.8 + (0.2 * value),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    accentColor.withOpacity(value),
                  ),
                ),
                const SizedBox(height: 24),
                Opacity(
                  opacity: value,
                  child: const Text(
                    'Loading profile...',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 64,
            color: Colors.white.withOpacity(0.4),
          ),
          const SizedBox(height: 16),
          Text(
            'Failed to load profile',
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: loadUserData,
            style: ElevatedButton.styleFrom(
              backgroundColor: accentColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    return SafeArea(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            // Profile Section
            ScaleTransition(
              scale: _profileScaleAnimation,
              child: FadeTransition(
                opacity: _profileFadeAnimation,
                child: _buildProfileSection(),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Stats Section
            SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.2),
                end: Offset.zero,
              ).animate(_menuSlideAnimation),
              child: FadeTransition(
                opacity: _menuSlideAnimation,
                child: _buildStatsSection,
              ),
            ),

            const SizedBox(height: 24),
            
            // Menu Section
            SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.4),
                end: Offset.zero,
              ).animate(_menuSlideAnimation),
              child: FadeTransition(
                opacity: _menuSlideAnimation,
                child: _buildMenuSection(),
              ),
            ),
          ],
        ),
      ),
    );
  }
Widget _buildProfileSection() {
    return Stack(
      children: [
        // Background gradient with animated shine effect
        Positioned.fill(
          child: TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 2000),
            tween: Tween(begin: -1.0, end: 1.0),
            builder: (context, value, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment(value, 0),
                    end: Alignment(value + 1, 0),
                    colors: [
                      accentColor.withOpacity(0.1),
                      accentColor.withOpacity(0.2),
                      accentColor.withOpacity(0.1),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        // Main content
        Column(
          children: [
            // Top section with curved design
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: cardColor,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    cardColor,
                    cardColor.withOpacity(0.8),
                    accentColor.withOpacity(0.1),
                  ],
                ),
              ),
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  // Background patterns
                  Positioned(
                    right: -50,
                    top: -50,
                    child: Transform.rotate(
                      angle: math.pi / 4,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              accentColor.withOpacity(0.1),
                              accentColor.withOpacity(0.05),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  // Profile content
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 40, 24, 100),
                    child: Column(
                      children: [
                        // Username and edit button row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '@${userData!.username}',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white.withOpacity(0.7),
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                HapticFeedback.mediumImpact();
                               Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => BlocProvider(
      create: (_) => ProfileEditCubit(),
      child: ProfileEditScreen(currentUser: auth.User(
        id: userData!.username ,
        username: userData!.username ,
        author_name : userData!.author_name ,
        profile: userData!.profile!
      ),
      
      )),
    ),
  );
                           
          
                              },
                              icon: Icon(
                                Icons.edit_outlined,
                                color: Colors.white.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // Profile picture overlapping the bottom
                  Positioned(
                    bottom: -60,
                    child: _buildProfilePicture(),
                  ),
                ],
              ),
            ),
            
            // Bottom section with user info
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 70, 24, 24),
              child: Column(
                children: [
                  // Author name
                  Text(
                    userData!.author_name,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Bio text
                  Text(
                    'Poet • Dreamer • Storyteller',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Quick action buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildQuickActionButton(
                        icon: Icons.edit_note_rounded,
                        label: 'Write',
                        onTap: () {
                          HapticFeedback.mediumImpact();
                         Navigator.push(context , 
                         MaterialPageRoute(builder: (context) => const CreatePoemScreen())
                         );
                        },
                      ),
                      const SizedBox(width: 16),
                      _buildQuickActionButton(
                        icon: Icons.share_rounded,
                        label: 'Share',
                        onTap: () {
                          HapticFeedback.mediumImpact();
    _shareProfile();
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
Future<void> _shareProfile() async {
  try {
    // Create a formatted share text
    final shareText = '''
🎭 Check out ${userData!.author_name}'s Poetry Profile!

📝 Total Poems: $totalPoems
👥 Followers: $user_followers
✨ Following: $user_following

@${userData!.username}
Join us in celebrating the art of poetry!
    ''';

    // Show a custom share bottom sheet
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildShareBottomSheet(shareText),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Failed to share profile: ${e.toString()}'),
        backgroundColor: Colors.red.withOpacity(0.8),
      ),
    );
  }
}

Widget _buildShareBottomSheet(String shareText) {
  return Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: cardColor,
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(20),
      ),
      border: Border.all(
        color: Colors.white.withOpacity(0.1),
      ),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 40,
          height: 4,
          margin: const EdgeInsets.only(bottom: 24),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Text(
          'Share Profile',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white.withOpacity(0.9),
          ),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildShareOption(
              icon: Icons.share_rounded,
              label: 'General',
              onTap: () async {
                Navigator.pop(context);
                await Share.share(shareText);
              },
            ),
            _buildShareOption(
              icon: Icons.message_rounded,
              label: 'Message',
              onTap: () async {
                Navigator.pop(context);
                final uri = Uri.parse('sms:?body=${Uri.encodeComponent(shareText)}');
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri);
                }
              },
            ),
            _buildShareOption(
              icon: Icons.email_rounded,
              label: 'Email',
              onTap: () async {
                Navigator.pop(context);
                final uri = Uri.parse('mailto:?subject=Check out this poetry profile&body=${Uri.encodeComponent(shareText)}');
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri);
                }
              },
            ),
            _buildShareOption(
              icon: Icons.copy_rounded,
              label: 'Copy',
              onTap: () async {
                Navigator.pop(context);
                await Clipboard.setData(ClipboardData(text: shareText));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Profile info copied to clipboard'),
                      backgroundColor: accentColor.withOpacity(0.8),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
            ),
          ],
        ),
        const SizedBox(height: 24),
      ],
    ),
  );
}

Widget _buildShareOption({
  required IconData icon,
  required String label,
  required VoidCallback onTap,
}) {
  return GestureDetector(
    onTap: () {
      HapticFeedback.mediumImpact();
      onTap();
    },
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: accentColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: accentColor.withOpacity(0.3),
            ),
          ),
          child: Icon(
            icon,
            color: accentColor,
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 12,
          ),
        ),
      ],
    ),
  );
}
  Widget _buildProfilePicture() {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 1500),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.8 + (0.2 * value),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  accentColor,
                  accentColor.withOpacity(0.7),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: accentColor.withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: backgroundColor,
                shape: BoxShape.circle,
              ),
              child: CircleAvatar(
                radius: 55,
                backgroundColor: cardColor,
                backgroundImage: NetworkImage(userData!.profile!),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            border: Border.all(
              color: accentColor.withOpacity(0.3),
            ),
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [
                accentColor.withOpacity(0.1),
                accentColor.withOpacity(0.05),
              ],
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: accentColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Add these getter methods for the stats section
  Widget get _buildStatsSection {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem('Poems', totalPoems.toString(), Icons.book_rounded),
          _buildVerticalDivider(),
          _buildStatItem('Following', user_following.toString(), Icons.people_outline_rounded),
          _buildVerticalDivider(),
          _buildStatItem('Followers', user_followers.toString(), Icons.favorite_rounded),
        ],
      ),
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      height: 30,
      width: 1,
      color: Colors.white.withOpacity(0.1),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: accentColor.withOpacity(0.7),
          size: 20,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.white.withOpacity(0.6),
          ),
        ),
      ],
    );
  }


  Widget _buildMenuSection() {
    final menuItems = [
      {
        'icon': Icons.book_rounded,
        'title': 'My Poems',
        'route': const AuthorPoemsScreen(),
      },
      {
        'icon': Icons.favorite_rounded,
        'title': 'Favorites',
        'route': FavoritePoemsScreen(),
      },
 
        {
      'icon': Icons.vpn_key_rounded, // Add this item
      'title': 'Private Key',
      'route': const PrivateKeyManagementScreen(),
    },
      {
        'icon': Icons.logout_rounded,
        'title': 'Logout',
        'isLogout': true,
      },
    ];

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: List.generate(menuItems.length, (index) {
          final item = menuItems[index];
          return TweenAnimationBuilder<double>(
            duration: Duration(milliseconds: 200 + (index * 100)),
            tween: Tween(begin: 0.0, end: 1.0),
            builder: (context, value, child) {
              return Transform.scale(
                scale: 0.95 + (0.05 * value),
                child: Opacity(
                  opacity: value,
                  child: child,
                ),
              );
            },
            child: _buildMenuItem(
              icon: item['icon'] as IconData,
              title: item['title'] as String,
              isLogout: item['isLogout'] as bool? ?? false,
              onTap: () => _handleMenuItemTap(item),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    bool isLogout = false,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isLogout ? Colors.red.withOpacity(0.1) : cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isLogout 
              ? Colors.red.withOpacity(0.3)
              : Colors.white.withOpacity(0.1),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 16,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isLogout ? Colors.red : accentColor,
                ),
                const SizedBox(width: 16),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: isLogout ? Colors.red : Colors.white,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.chevron_right_rounded,
                  color: isLogout 
                      ? Colors.red.withOpacity(0.5)
                      : Colors.white.withOpacity(0.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleMenuItemTap(Map<String, dynamic> item) async {
    HapticFeedback.mediumImpact();
    
    if (item['isLogout'] == true) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => _buildLogoutDialog(),
      );
      
      if (confirmed == true && mounted) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();
        // Navigate to login screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const AuthorPoemsScreen(),
          ),
        );
      }
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => item['route'] as Widget,
        ),
      );
    }
  }

  Widget _buildLogoutDialog() {
    return AlertDialog(
      backgroundColor: surfaceColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      title: const Text(
        'Logout',
        style: TextStyle(color: Colors.white),
      ),
      content: const Text(
        'Are you sure you want to logout?',
        style: TextStyle(color: Colors.white70),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(
            'Cancel',
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
            ),
          ),
        ),
        TextButton(
          onPressed: () async {
            final prefs = await SharedPreferences.getInstance();
            await prefs.clear();
             Navigator.pop(context, true);
             
          },
          style: TextButton.styleFrom(
            foregroundColor: Colors.red,
          ),
          child: const Text('Logout'),
        ),
      ],
    );
  }
}