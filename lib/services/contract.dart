import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart' as db;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:test_app/model.dart' as m;
import 'package:web3dart/web3dart.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart'; //You can also import the browser version

class PoetsLoomService {
  final Web3Client _client;
  final String _privateKey;
  final EthereumAddress _contractAddress;
  late DeployedContract _contract;
  late Credentials _credentials;
final db.FirebaseDatabase database = db.FirebaseDatabase.instance;

  PoetsLoomService({
    required String rpcUrl,
    required String privateKey,
    required String contractAddress,
  }) : _client = Web3Client(rpcUrl, Client()),
       _privateKey = privateKey,
       _contractAddress = EthereumAddress.fromHex(contractAddress) {
    _initialize();
  }


Future<String?> uploadPoemWithHashedKey(String title, String content , List<String> tags) async {
  try {
    // Retrieve the username from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString("authorName") ?? "Anonamous ";

    // Get the current timestamp
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    // Generate a hash key
    final key = _generateHashKey(username, title, timestamp);

    // Create the data map ensuring all values are JSON-serializable
    final Map<String, dynamic> poemData = {
      'content': content,
      'timestamp': timestamp.toString(), // Convert to string to ensure compatibility
      'title': title,
      'author': username,
      'createdAt': db.ServerValue.timestamp, // Use server timestamp
    'likes' : 0,
    'rewards' : 0,
    'tags' : tags
    };

    try {
      // Use set() with toJson() to ensure proper serialization
      print("uploading data to the firebase db");

      await db.FirebaseDatabase.instance
          .ref()
          .child('poems')
          .child(key)
          .set(jsonDecode(jsonEncode(poemData)));

      
      final supabaseClient = SupabaseClient('https://tfxbcnluzthdrwhtrntb.supabase.co', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRmeGJjbmx1enRoZHJ3aHRybnRiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzA0NjI2NjksImV4cCI6MjA0NjAzODY2OX0.at0R_6S9vUk666sS1xJA_2jIoRLez_YN2PBLo_822vM');
  final _prefs = await SharedPreferences.getInstance();
  final id = json.decode(_prefs.getString("user_data")!)["id"];
      await supabaseClient.from("poems").insert({
        'userId': id,
        'poemHash': key,
      });

      print('Successfully uploaded poem with key: $key');
      return key;
    } on Object catch (e) {
      // Handle web-specific Firebase errors
      // if (js_util.hasProperty(e, 'message')) {
      //   print('Firebase web error: ${js_util.getProperty(e, 'message')}');
      // } else {
      //   print('Unknown error: $e');
      // }
      return null;
    }
  } catch (e) {
    print('Error uploading poem: $e');
    return null;
  }
}
  Future<String> getProfile(int userId) async {
      final supabaseClient = SupabaseClient('https://tfxbcnluzthdrwhtrntb.supabase.co', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRmeGJjbmx1enRoZHJ3aHRybnRiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzA0NjI2NjksImV4cCI6MjA0NjAzODY2OX0.at0R_6S9vUk666sS1xJA_2jIoRLez_YN2PBLo_822vM');
      final result = await supabaseClient.
      from("users")
      .select("*")
      .eq("id", userId).single();

      if (result.toString().isEmpty) {
throw Exception("User not found");

      }

      final profile = result["profile"];

      return profile.toString();

  }


/// Adds a follower to the current user's following list in the Supabase database.
///
/// This function inserts a record into the "following" table in Supabase with the
/// provided `followerId` as the `authorId` and the current user's ID as the `userId`.
///
/// Throws an exception if unable to add the follower.
///
/// Parameters:
/// - `followerId`: The ID of the user to be followed.
///
/// Returns:
/// A `Future` that resolves to `null` if the operation is successful.

Future<String?> addFollower(int followerId) async {
              final supabaseClient = SupabaseClient('https://tfxbcnluzthdrwhtrntb.supabase.co', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRmeGJjbmx1enRoZHJ3aHRybnRiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzA0NjI2NjksImV4cCI6MjA0NjAzODY2OX0.at0R_6S9vUk666sS1xJA_2jIoRLez_YN2PBLo_822vM');
  try{
  final _prefs = await SharedPreferences.getInstance();
  final id = json.decode(_prefs.getString("user_data")!)["id"];
await supabaseClient.from("following").insert({
  'userId' : id,
  'authorId' : followerId
});
  }catch(e){
    print(e);
    throw Exception("Unable to add follower ${e}");
  }

}

Future<String> addFavorite(int poemId) async {
  final supabaseClient = SupabaseClient('https://tfxbcnluzthdrwhtrntb.supabase.co', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRmeGJjbmx1enRoZHJ3aHRybnRiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzA0NjI2NjksImV4cCI6MjA0NjAzODY2OX0.at0R_6S9vUk666sS1xJA_2jIoRLez_YN2PBLo_822vM');
  try{
  final _prefs = await SharedPreferences.getInstance();
  final id = json.decode(_prefs.getString("user_data")!)["id"];
await supabaseClient.from("favorite").insert({
  'userId' : id,
  'poemId' : poemId
});
  }catch(e){
    print(e);
    throw Exception("Unable to add favorite ${e}");
  }

return "success";
}


Future<List<int>> getFavorites() async {

  final supabaseClient = SupabaseClient('https://tfxbcnluzthdrwhtrntb.supabase.co', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRmeGJjbmx1enRoZHJ3aHRybnRiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzA0NjI2NjksImV4cCI6MjA0NjAzODY2OX0.at0R_6S9vUk666sS1xJA_2jIoRLez_YN2PBLo_822vM');
  try{
  final _prefs = await SharedPreferences.getInstance();
  final id = json.decode(_prefs.getString("user_data")!)["id"];
final result = await supabaseClient.from("favorite").select("poemId").eq("userId", int.parse(id));

  if (result.toString().isEmpty) {
    return [];
  }

  final poemIds = result.map((poem) => int.parse (poem["poemId"].toString())).toList();
  print(poemIds);
  return poemIds;

  }catch(e){
    print(e);
    throw Exception("Unable to add favorite ${e}");
  }

}
  

Future<String> removeFromFavorites(int poemId) async {
  final supabaseClient = SupabaseClient('https://tfxbcnluzthdrwhtrntb.supabase.co', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRmeGJjbmx1enRoZHJ3aHRybnRiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzA0NjI2NjksImV4cCI6MjA0NjAzODY2OX0.at0R_6S9vUk666sS1xJA_2jIoRLez_YN2PBLo_822vM');
  try{
  final _prefs = await SharedPreferences.getInstance();
  final id = json.decode(_prefs.getString("user_data")!)["id"];
await supabaseClient.from("favorite").delete().eq('userId', id).eq('poemId', poemId);
  }catch(e){
    print(e);
    throw Exception("Unable to remove the  favorite ${e}");
  }

return "success";
}




Future<String?> updatePoem(String title, String content , int userId , String key) async {
  try {
  
    try {
      // Use set() with toJson() to ensure proper serialization
      print("updating data to the firebase db with titke {$title} and content {$content}");

      await db.FirebaseDatabase.instance
          .ref()
          .child('poems')
          .child(key)
          .update({
           
          "content": content,
         
          });
               await db.FirebaseDatabase.instance
          .ref()
          .child('poems')
          .child(key)
          .update({
           
          "title": title,
         
          });
      
             

      print('Successfully uploaded poem with key: $key');
      return key;
    } on Object catch (e) {
      // Handle web-specific Firebase errors
      // if (js_util.hasProperty(e, 'message')) {
      //   print('Firebase web error: ${js_util.getProperty(e, 'message')}');
      // } else {
      //   print('Unknown error: $e');
      // }
      return null;
    }
  } catch (e) {
    print('Error uploading poem: $e');
    return null;
  }
}

// Helper function to generate a hash key
String _generateHashKey(String username, String title, int timestamp) {
  final String combined = '$username:$title:$timestamp';
  final bytes = utf8.encode(combined);
  final hash = sha256.convert(bytes);
  return hash.toString().substring(0, 32);
}

// Function to retrieve poem data that works in web
Future<Map<String, dynamic>?> retrievePoemByKey(String key) async {
  try {
    final snapshot = await db.FirebaseDatabase.instance
        .ref()
        .child('poems')
        .child(key)
        .get();

    if (snapshot.exists) {
      // Convert to JSON and back to ensure proper type conversion
      final jsonString = jsonEncode(snapshot.value);
      return Map<String, dynamic>.from(jsonDecode(jsonString));
    }
    return null;
  } on Object catch (e) {
    // Handle web-specific errors
    // if (js_util.hasProperty(e, 'message')) {
    //   print('Firebase web error during retrieval: ${js_util.getProperty(e, 'message')}');
    // } else {
    //   print('Error retrieving poem: $e');
    // }
    return null;
  }
}

// Optional: Add a function to validate the data before upload
bool validatePoemData(String title, String content) {
  if (title.trim().isEmpty || content.trim().isEmpty) {
    return false;
  }
  if (title.length > 100) {
    return false;
  }
  if (content.length > 50000) {
    return false;
  }
  return true;
}


Future<String> addComment(int poemId, String comment) async {

final supabaseClient = SupabaseClient('https://tfxbcnluzthdrwhtrntb.supabase.co', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRmeGJjbmx1enRoZHJ3aHRybnRiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzA0NjI2NjksImV4cCI6MjA0NjAzODY2OX0.at0R_6S9vUk666sS1xJA_2jIoRLez_YN2PBLo_822vM');
  try{
  final _prefs = await SharedPreferences.getInstance();
  final id = json.decode(_prefs.getString("user_data")!)["id"];

await supabaseClient.from("comments").insert({
  'userId' : id,
  'poemId' : poemId,
  'comment' : comment,
      'timestamp': DateTime.now().toIso8601String(), // Convert DateTime to ISO 8601 string
});

return "success";
  }catch(e){
    print(e);
    throw Exception("Unable to add comment ${e}");
  }


}


Future<List<m.Comment>> getComments(int poemId) async {

final supabaseClient = SupabaseClient('https://tfxbcnluzthdrwhtrntb.supabase.co', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRmeGJjbmx1enRoZHJ3aHRybnRiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzA0NjI2NjksImV4cCI6MjA0NjAzODY2OX0.at0R_6S9vUk666sS1xJA_2jIoRLez_YN2PBLo_822vM');
  try{

final result = await supabaseClient.from("comments").select("*").eq("poemId", poemId);

List<m.Comment> comments = [];

for (var comment in result) {
  final userName  = await supabaseClient.from("users").select("*").eq("id", comment["userId"]).single();
comments.add(
  m.Comment(
    id: poemId.toString(),
    content: comment["comment"],
    timestamp: DateTime.parse(comment["timestamp"]), // Convert string to DateTime
    author: userName["author_name"],
  ),
);}
print("the commetns are : ${comments}");
return comments;
  }catch(e){
    print(e);
    throw Exception("Unable to add comment ${e}");
  }


}
Future<Map?> retrievePoemContent(String hashKey) async {
  try {
    // Create a reference to the Realtime Database
    final db.DatabaseReference databaseReference = db.FirebaseDatabase.instance.ref();

    // Retrieve the poem content using the hashed key
    db.DataSnapshot snapshot = await databaseReference.child('poems').child(hashKey).get();

    // Check if the snapshot has data
    if (snapshot.exists) {
      // Return the content of the poem
      final poemData = snapshot.value as Map<dynamic, dynamic>;
      return poemData; // Return the content as a String
    } else {
      print("Poem not found.");
      return null; // Return null if the poem doesn't exist
    }
  } catch (e) {
    print("Error retrieving poem: $e"); // Log the error
    return null; // Return null if there's an error
  }
}

Future<int?> retrieveLikes(String hashKey) async {
  try {
    // Create a reference to the Realtime Database
    final db.DatabaseReference databaseReference = db.FirebaseDatabase.instance.ref();

    // Retrieve the poem content using the hashed key
    db.DataSnapshot snapshot = await databaseReference.child('poems').child(hashKey).get();

    // Check if the snapshot has data
    if (snapshot.exists) {
      // Return the content of the poem
      final poemData = snapshot.value as Map<dynamic, dynamic>;
      return poemData['likes'] as int; // Return the content as a String
    } else {
      print("Poem not found.");
      return null; // Return null if the poem doesn't exist
    }
  } catch (e) {
    print("Error retrieving poem: $e"); // Log the error
    return null; // Return null if there's an error
  }
}
// Function to generate a hash key
String generateHashKey(String username, String title, int timestamp) {
  // Combine the username, title, and timestamp into a single string
  final combinedString = '$username$title$timestamp';

  // Create a SHA-256 hash of the combined string
  final bytes = utf8.encode(combinedString); // Convert to UTF-8
  final digest = sha256.convert(bytes); // Hash the bytes

  // Return the hash as a hexadecimal string
  return digest.toString();
}

  Future<void> _initialize() async {
    
    // Load contract ABI
    _contract = DeployedContract(
      ContractAbi.fromJson(_abiJson, 'PoetsLoom'),
      _contractAddress,
    );
    _credentials = EthPrivateKey.fromHex(_privateKey);
    database.databaseURL = "https://poetloom-default-rtdb.firebaseio.com/";
  }

  Future<void> dispose() async {
    await _client.dispose();
  }

  // Add a new poem
Future<String> addPoem(String title, String encryptedIpfsHash, String authorName) async {
  final function = _contract.function('addPoem');
  final _prefs = await SharedPreferences.getInstance();
  final id = json.decode(_prefs.getString("user_data")!)["id"];
  
  // Convert id to BigInt for uint256 parameter
  final userId = BigInt.from(int.parse(id));
  
  try {
    final result = await _client.sendTransaction(
      _credentials,
      Transaction.callContract(
        contract: _contract,
        function: function,
        parameters: [
          title,                // string _title
          encryptedIpfsHash,    // string _encryptedIpfsHash
          authorName,           // string _author
          userId               // uint256 id - Make sure to pass as BigInt
        ],
      ),
      chainId: 11155111, // Sepolia chain ID
    );
    
    print("Transaction hash: ${result.toString()}");
    return result;
  } catch (e) {
    throw Exception('Failed to add poem: ${e.toString()}');
  }
}

  // Get poem by ID
  Future<Map<String, dynamic>> getPoemById(BigInt poemId) async {
    final function = _contract.function('getPoemById');
    
    try {
      final result = await _client.call(
        contract: _contract,
        function: function,
        params: [poemId],
      );
      
      return {
        'title': result[0],
        'encryptedIpfsHash': result[1],
        'author': result[2],
        'timestamp': DateTime.fromMillisecondsSinceEpoch(
          (result[3] as BigInt).toInt() * 1000
        ),
        'poemId': result[4],
        'likes': result[5],
        'authorName': result[7],
        'likedBy': result[6],
      };
    } catch (e) {
      throw Exception('Failed to get poem: ${e.toString()}');
    }
  }


  
  
  
  // Get all poems
  Future<List> getPoems() async {
    final function = _contract.function('getPoems');
    
    
    try {
      final result = await _client.call(
        contract: _contract,
        function: function,
        params: [],
      );
    print("the result is ${result}");

      final List<dynamic> poemsList = result[0];
       poemsList.map((poem) => {
        'title': poem[0],
        'encryptedIpfsHash': poem[1],
        'author': poem[2],
        'timestamp': DateTime.fromMillisecondsSinceEpoch(
          (poem[3] as BigInt).toInt() * 1000
        ),
        'poemId': poem[4],
        'likes': poem[5],
        'authorName': poem[7],
        'liked': poem[6],
      }).toList();
         print("The poems are ${poemsList}");
        return poemsList;
    } catch (e) {
      throw Exception('Failed to get poems: ${e.toString()}');
    }
  }
  Future<String> likePoem(String poemHash , int likes , int poemId) async {

  try{
        final supabaseClient = SupabaseClient('https://tfxbcnluzthdrwhtrntb.supabase.co', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRmeGJjbmx1enRoZHJ3aHRybnRiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzA0NjI2NjksImV4cCI6MjA0NjAzODY2OX0.at0R_6S9vUk666sS1xJA_2jIoRLez_YN2PBLo_822vM');

          final _prefs = await SharedPreferences.getInstance();
          final id = await json.decode(_prefs.getString("user_data")!)["id"];

          // check if already liked the poem
          final result = await supabaseClient.from("likes")
          .select("*")
          .eq('userid', id)
          .eq('poemId', poemId);

          if(result.isNotEmpty ){
            throw Exception('Poem already liked');
          }

            await supabaseClient.from("likes").insert({
            'userid': id,
            'poemId': poemId,
          });

          await db.FirebaseDatabase.instance
          .ref()
          .child('poems')
          .child(poemHash)
          .child("likes").set(likes);

          // add to supbase 

         

  }catch(e){
    print('Failed to like poem: ${e.toString()}');
    throw Exception('Failed to like poem: ${e.toString()}');
  }
  return "success";

  }

  Future<bool> isLikedPoem(BigInt poemid) async {
    try{
      int poemId = poemid.toInt();
          final _prefs = await SharedPreferences.getInstance();
          final id = await json.decode(_prefs.getString("user_data")!)["id"];

            final supabaseClient = SupabaseClient('https://tfxbcnluzthdrwhtrntb.supabase.co', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRmeGJjbmx1enRoZHJ3aHRybnRiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzA0NjI2NjksImV4cCI6MjA0NjAzODY2OX0.at0R_6S9vUk666sS1xJA_2jIoRLez_YN2PBLo_822vM');
            final result = await supabaseClient.from("likes")
            .select("*")
            .eq('userid', int.parse(id))
            .eq('poemId', poemId);
            
            if (result.isNotEmpty){
              return true;
            }
            return false;
    }catch(e){
      print("the errir is ${e}");
      return false;
    }
  }



    // final function = _contract.function('likePoem');
    // final prefs = await SharedPreferences.getInstance();
    // // Ensure we're parsing the ID correctly
    // final userData = json.decode(prefs.getString("user_data") ?? "{}");
    // if (!userData.containsKey("id")) {
    //   throw Exception('User ID not found in preferences');
    // }
    
    // final id = BigInt.from(int.parse(userData["id"]));
    
    // try {
    //   // Add gas limit to ensure transaction goes through
    //   final result = await _client.sendTransaction(
    //     _credentials,
    //     Transaction.callContract(
    //       contract: _contract,
    //       function: function,
    //       parameters: [poemId, id],
    //       maxGas: 49440, // Add reasonable gas limit
    //     ),
    //     chainId: 11155111,
    //   );
      
    //   // Wait for transaction receipt to confirm
    // print("the result is ${result}");
      
    //   return result;
    // } catch (e) {
    //   print('Error in likePoem: ${e.toString()}');
    //   throw Exception('Failed to like poem: ${e.toString()}');
    // }
  // Fixed reward poem function
  Future<String> rewardPoem(BigInt poemId, BigInt amount , int authorId , String poemHash , int reward )async {
    final function = _contract.function('rewardPoem');
    print("poemId is ${poemId} with reward ${amount}");
    try {
      // Convert amount to Wei if it's not already

      final weiAmount = EtherAmount.fromBigInt(EtherUnit.wei, amount);
      
      // Add gas limit and proper value handling
      final result = await _client.sendTransaction(
        _credentials,
        Transaction.callContract(
          contract: _contract,
          function: function,
          parameters: [poemId],
          value: weiAmount,
          maxGas: 100000, // Add reasonable gas limit
        ),
        chainId: 11155111,
      );
      
      // Wait for transaction receipt to confirm
  
      print(result.toString());
      if (result.isEmpty) {
        throw Exception('Transaction failed: No receipt received');
      }
      

              final supabaseClient = SupabaseClient('https://tfxbcnluzthdrwhtrntb.supabase.co', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRmeGJjbmx1enRoZHJ3aHRybnRiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzA0NjI2NjksImV4cCI6MjA0NjAzODY2OX0.at0R_6S9vUk666sS1xJA_2jIoRLez_YN2PBLo_822vM');

          final _prefs = await SharedPreferences.getInstance();
          final id = await json.decode(_prefs.getString("user_data")!)["id"];

          final res = await supabaseClient.from("rewards")
            .insert({"userId":int.parse(id), "authorId": authorId, "amount": amount.toDouble()});
          
          if (res.toString().isEmpty) {
            throw Exception('Failed to reward poem: ${res}');
          }
          
      await db.FirebaseDatabase.instance
          .ref()
          .child('poems')
          .child(poemHash)
          .child("rewards").set(reward);


      return result;
    } catch (e) {
      print('Error in rewardPoem: ${e.toString()}');
      throw Exception('Failed to reward poem: ${e.toString()}');
    }
  }


  Future<List<double>> getRewards() async {
     final _prefs = await SharedPreferences.getInstance();
          final id = await json.decode(_prefs.getString("user_data")!)["id"];
              final supabaseClient = SupabaseClient('https://tfxbcnluzthdrwhtrntb.supabase.co', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRmeGJjbmx1enRoZHJ3aHRybnRiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzA0NjI2NjksImV4cCI6MjA0NjAzODY2OX0.at0R_6S9vUk666sS1xJA_2jIoRLez_YN2PBLo_822vM');
          print("fetching rewards");
          final result = await supabaseClient
          .from("rewards")
          .select("*")
          .eq("authorId", int.parse(id));

       
        print(" the rewards are ${result}");
          List<double> rewards = [];
          for (var reward in result) {
             final weiAmount = EtherAmount.fromBigInt(EtherUnit.wei, BigInt.from(reward['amount']));
  final ethAmount = weiAmount.getValueInUnit(EtherUnit.ether); // Converts wei to ETH
            rewards.add(ethAmount);
          }
          print(" the rewards in the eht are ${rewards}");
          return rewards;

  }
  // Withdraw rewards
  Future<String> withdrawAmount() async {
    final function = _contract.function('withdrawAmount');
    
    try {
      final result = await _client.sendTransaction(
        _credentials,
        Transaction.callContract(
          contract: _contract,
          function: function,
          parameters: [],
        ),
        chainId: 11155111,
      );
      
      return result;
    } catch (e) {
      throw Exception('Failed to withdraw rewards: ${e.toString()}');
    }
  }

  

  // Get author rewards
  Future<BigInt> getAuthorRewards() async {
    EthereumAddress author  = EthPrivateKey.fromHex(_privateKey).address;
    final function = _contract.function('authorRewards');
    
    try {
      final result = await _client.call(
        contract: _contract,
        function: function,
        params: [author],
      );
      
      return result[0];
    } catch (e) {
      throw Exception('Failed to get author rewards: ${e.toString()}');
    }
  }

  Future<List> getAuthorPoems(BigInt id) async {
    
    final function = _contract.function('getAuthorPoems');
    
    try {
      final result = await _client.call(
        contract: _contract,
        function: function,
        params: [id],
      );
     print("the author poems are  result is ${result}");

      final List<dynamic> poemsList = result[0];
       poemsList.map((poem) => {
        'title': poem[0],
        'encryptedIpfsHash': poem[1],
        'author': poem[2],
        'timestamp': DateTime.fromMillisecondsSinceEpoch(
          (poem[3] as BigInt).toInt() * 1000
        ),
        'poemId': poem[4],
        'likes': poem[5],
        'authorName': poem[7],
        'liked': poem[6],
      }).toList();
         print("The author  poems are ${poemsList}");
        return poemsList;
    } catch (e) {
      throw Exception('Failed to get poems: ${e.toString()}');
    }
  }

  static const String _abiJson = '''
  [
    {
      "anonymous": false,
      "inputs": [
        {
          "indexed": false,
          "internalType": "string",
          "name": "error",
          "type": "string"
        }
      ],
      "name": "Error",
      "type": "event"
    },
    {
      "anonymous": false,
      "inputs": [
        {
          "indexed": false,
          "internalType": "uint256",
          "name": "_poemId",
          "type": "uint256"
        }
      ],
      "name": "LikedPoem",
      "type": "event"
    },
    {
      "anonymous": false,
      "inputs": [
        {
          "indexed": false,
          "internalType": "string",
          "name": "title",
          "type": "string"
        },
        {
          "indexed": false,
          "internalType": "uint256",
          "name": "_poemCount",
          "type": "uint256"
        },
        {
          "indexed": false,
          "internalType": "address",
          "name": "author",
          "type": "address"
        }
      ],
      "name": "PoemEvent",
      "type": "event"
    },
    {
      "anonymous": false,
      "inputs": [
        {
          "indexed": false,
          "internalType": "uint256",
          "name": "poemId",
          "type": "uint256"
        },
        {
          "indexed": false,
          "internalType": "uint256",
          "name": "amount",
          "type": "uint256"
        }
      ],
      "name": "RewardGiven",
      "type": "event"
    },
    {
      "anonymous": false,
      "inputs": [
        {
          "indexed": false,
          "internalType": "uint256",
          "name": "amount",
          "type": "uint256"
        }
      ],
      "name": "RewardWithdrawn",
      "type": "event"
    },
    {
      "inputs": [],
      "name": "MAX_AUTHOR_NAME_LENGTH",
      "outputs": [
        {
          "internalType": "uint256",
          "name": "",
          "type": "uint256"
        }
      ],
      "stateMutability": "view",
      "type": "function"
    },
    {
      "inputs": [],
      "name": "MAX_POEM_TITLE_LENGTH",
      "outputs": [
        {
          "internalType": "uint256",
          "name": "",
          "type": "uint256"
        }
      ],
      "stateMutability": "view",
      "type": "function"
    },
    {
      "inputs": [],
      "name": "MINIMUM_WITHDRAWAL",
      "outputs": [
        {
          "internalType": "uint256",
          "name": "",
          "type": "uint256"
        }
      ],
      "stateMutability": "view",
      "type": "function"
    },
    {
      "inputs": [
        {
          "internalType": "string",
          "name": "_title",
          "type": "string"
        },
        {
          "internalType": "string",
          "name": "_encryptedIpfsHash",
          "type": "string"
        },
        {
          "internalType": "string",
          "name": "_author",
          "type": "string"
        },
        {
          "internalType": "uint256",
          "name": "id",
          "type": "uint256"
        }
      ],
      "name": "addPoem",
      "outputs": [],
      "stateMutability": "nonpayable",
      "type": "function"
    },
    {
      "inputs": [
        {
          "internalType": "address",
          "name": "",
          "type": "address"
        }
      ],
      "name": "authorRewards",
      "outputs": [
        {
          "internalType": "uint256",
          "name": "",
          "type": "uint256"
        }
      ],
      "stateMutability": "view",
      "type": "function"
    },
    {
      "inputs": [
        {
          "internalType": "uint256",
          "name": "id",
          "type": "uint256"
        }
      ],
      "name": "getAuthorPoems",
      "outputs": [
        {
          "components": [
            {
              "internalType": "string",
              "name": "title",
              "type": "string"
            },
            {
              "internalType": "string",
              "name": "encryptedIpfsHash",
              "type": "string"
            },
            {
              "internalType": "address",
              "name": "author",
              "type": "address"
            },
            {
              "internalType": "uint256",
              "name": "id",
              "type": "uint256"
            },
            {
              "internalType": "uint256",
              "name": "timestamp",
              "type": "uint256"
            },
            {
              "internalType": "uint256",
              "name": "poemId",
              "type": "uint256"
            },
            {
              "internalType": "uint256",
              "name": "likes",
              "type": "uint256"
            },
            {
              "internalType": "uint256[]",
              "name": "liked",
              "type": "uint256[]"
            },
            {
              "internalType": "string",
              "name": "authorName",
              "type": "string"
            }
          ],
          "internalType": "struct PoetsLoom.poem[]",
          "name": "",
          "type": "tuple[]"
        }
      ],
      "stateMutability": "view",
      "type": "function"
    },
    {
      "inputs": [
        {
          "internalType": "uint256",
          "name": "_poemId",
          "type": "uint256"
        }
      ],
      "name": "getPoemById",
      "outputs": [
        {
          "internalType": "string",
          "name": "",
          "type": "string"
        },
        {
          "internalType": "string",
          "name": "",
          "type": "string"
        },
        {
          "internalType": "address",
          "name": "",
          "type": "address"
        },
        {
          "internalType": "uint256",
          "name": "",
          "type": "uint256"
        },
        {
          "internalType": "uint256",
          "name": "",
          "type": "uint256"
        },
        {
          "internalType": "uint256",
          "name": "",
          "type": "uint256"
        },
        {
          "internalType": "string",
          "name": "",
          "type": "string"
        },
        {
          "internalType": "uint256[]",
          "name": "",
          "type": "uint256[]"
        },
        {
          "internalType": "uint256",
          "name": "id",
          "type": "uint256"
        }
      ],
      "stateMutability": "view",
      "type": "function"
    },
    {
      "inputs": [],
      "name": "getPoems",
      "outputs": [
        {
          "components": [
            {
              "internalType": "string",
              "name": "title",
              "type": "string"
            },
            {
              "internalType": "string",
              "name": "encryptedIpfsHash",
              "type": "string"
            },
            {
              "internalType": "address",
              "name": "author",
              "type": "address"
            },
            {
              "internalType": "uint256",
              "name": "id",
              "type": "uint256"
            },
            {
              "internalType": "uint256",
              "name": "timestamp",
              "type": "uint256"
            },
            {
              "internalType": "uint256",
              "name": "poemId",
              "type": "uint256"
            },
            {
              "internalType": "uint256",
              "name": "likes",
              "type": "uint256"
            },
            {
              "internalType": "uint256[]",
              "name": "liked",
              "type": "uint256[]"
            },
            {
              "internalType": "string",
              "name": "authorName",
              "type": "string"
            }
          ],
          "internalType": "struct PoetsLoom.poem[]",
          "name": "",
          "type": "tuple[]"
        }
      ],
      "stateMutability": "view",
      "type": "function"
    },
    {
      "inputs": [
        {
          "internalType": "uint256",
          "name": "_poemId",
          "type": "uint256"
        },
        {
          "internalType": "uint256",
          "name": "id",
          "type": "uint256"
        }
      ],
      "name": "likePoem",
      "outputs": [],
      "stateMutability": "nonpayable",
      "type": "function"
    },
    {
      "inputs": [
        {
          "internalType": "uint256",
          "name": "",
          "type": "uint256"
        }
      ],
      "name": "poems",
      "outputs": [
        {
          "internalType": "string",
          "name": "title",
          "type": "string"
        },
        {
          "internalType": "string",
          "name": "encryptedIpfsHash",
          "type": "string"
        },
        {
          "internalType": "address",
          "name": "author",
          "type": "address"
        },
        {
          "internalType": "uint256",
          "name": "id",
          "type": "uint256"
        },
        {
          "internalType": "uint256",
          "name": "timestamp",
          "type": "uint256"
        },
        {
          "internalType": "uint256",
          "name": "poemId",
          "type": "uint256"
        },
        {
          "internalType": "uint256",
          "name": "likes",
          "type": "uint256"
        },
        {
          "internalType": "string",
          "name": "authorName",
          "type": "string"
        }
      ],
      "stateMutability": "view",
      "type": "function"
    },
    {
      "inputs": [
        {
          "internalType": "uint256",
          "name": "_poemId",
          "type": "uint256"
        }
      ],
      "name": "rewardPoem",
      "outputs": [],
      "stateMutability": "payable",
      "type": "function"
    },
    {
      "inputs": [
        {
          "internalType": "uint256",
          "name": "",
          "type": "uint256"
        },
        {
          "internalType": "uint256",
          "name": "",
          "type": "uint256"
        }
      ],
      "name": "userLikedPoems",
      "outputs": [
        {
          "internalType": "bool",
          "name": "",
          "type": "bool"
        }
      ],
      "stateMutability": "view",
      "type": "function"
    },
    {
      "inputs": [],
      "name": "withdrawAmount",
      "outputs": [],
      "stateMutability": "nonpayable",
      "type": "function"
    }
  ]
''';

}