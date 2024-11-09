import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'package:path/path.dart' as path;

abstract class ProfileEditState extends Equatable {
  @override
  List<Object?> get props => [];
}

class ProfileEditInitial extends ProfileEditState {}
class ProfileEditLoading extends ProfileEditState {}
class ProfileEditSuccess extends ProfileEditState {}
class ProfileEditFailure extends ProfileEditState {
  final String error;
  ProfileEditFailure(this.error);

  @override
  List<Object?> get props => [error];
}

// profile_edit_cubit.dart

class ProfileEditCubit extends Cubit<ProfileEditState> {
  
  ProfileEditCubit() : super(ProfileEditInitial());

  Future<void> updateProfile({
    required String authorName,
    File? imageFile,
  }) async {
        final supabaseClient = SupabaseClient('https://tfxbcnluzthdrwhtrntb.supabase.co', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRmeGJjbmx1enRoZHJ3aHRybnRiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzA0NjI2NjksImV4cCI6MjA0NjAzODY2OX0.at0R_6S9vUk666sS1xJA_2jIoRLez_YN2PBLo_822vM');

    try {
      emit(ProfileEditLoading());

    print("updating profile");

      final prefs = await SharedPreferences.getInstance();
      final userId  = json.decode(await prefs.getString("user_data")!)["id"];
      String? imageUrl;
      if (imageFile != null) {
        // Upload image
          final timestamp = DateTime.now().millisecondsSinceEpoch;
    final extension = path.extension(imageFile.path);
    final fileName = 'profile_$timestamp$extension';

    // Upload image to Supabase Storage
    final storageResponse = await supabaseClient
        .storage
        .from('user_profile') // Your bucket name
        .uploadBinary(
          fileName,
          imageFile.readAsBytesSync(),
          fileOptions: const FileOptions(
            contentType: 'image/jpeg',
            upsert: true,
          ),
        );

    if (storageResponse.isEmpty) {
      throw Exception('Failed to upload image while editing profile: ${storageResponse.toString()}');
    }

    // Get the public URL of the uploaded image
    final imageUrl = await supabaseClient
        .storage
        .from('user_profile')
        .createSignedUrl(fileName , 10000000000);

         print("the iamge url is $imageUrl");

      }
      print("the iamge url is $imageUrl");

      await supabaseClient.from('users').update({
        'author_name': authorName.toString(),
        if (imageFile != null) 'profile': imageUrl,
      }).eq('id', int.parse(userId));


      emit(ProfileEditSuccess());
    } catch (e) {
      emit(ProfileEditFailure("Failed to update profile: $e"));
    }
  }
}
