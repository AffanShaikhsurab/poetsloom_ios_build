import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:test_app/authservice.dart';
import 'package:test_app/model.dart' as m;
import 'package:test_app/widget/custom_button.dart';


class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = false;
  late m.User _user;
  List<m.Poem> _userPoems = [];

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    setState(() => _isLoading = true);
    try {
      // TODO: Implement profile loading
      // _user = await UserService.getCurrentUser();
      // _userPoems = await PoemService.getUserPoems(_user.id);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load profile')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () {
              Provider.of<AuthService>(context, listen: false).logout();
            },
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadUserProfile,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    SizedBox(height: 24),
                    CircleAvatar(
                      radius: 50,
                      backgroundImage: NetworkImage(_user.avatar),
                    ),
                    SizedBox(height: 16),
                    Text(
                      _user.username,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '@${_user.username}',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                    SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStatColumn('Poems', _user.totalPoems.toString()),
                        _buildStatColumn(
                            'Followers', _user.followers.length.toString()),
                        _buildStatColumn(
                            'Following', _user.following.length.toString()),
                        _buildStatColumn('Rewards', _user.totalRewards.toString()),
                      ],
                    ),
                    SizedBox(height: 24),
                    Divider(),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: _userPoems.length,
                      itemBuilder: (context, index) {
                        return PoemCard(
                          poem: _userPoems[index],
                          onLike: () async {
                            // TODO: Implement like functionality
                          },
                          onReward: () async {
                            // TODO: Implement reward functionality
                          },
                          onFollow: () async {
                            // TODO: Implement follow functionality
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatColumn(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
}