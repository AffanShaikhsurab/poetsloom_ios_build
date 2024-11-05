
import 'package:flutter/material.dart';
import 'package:web3dart/web3dart.dart';
import 'package:http/http.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PoemStorage DApp',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: PoemStorageUI(),
    );
  }
}

class PoemStorageUI extends StatefulWidget {
  @override
  _PoemStorageUIState createState() => _PoemStorageUIState();
}

class _PoemStorageUIState extends State<PoemStorageUI> {
  Web3Client? client;
  Credentials? credentials;
  DeployedContract? contract;
  bool isLoading = true;
  String errorMessage = '';
  TextEditingController titleController = TextEditingController();
  TextEditingController ipfsHashController = TextEditingController();
  TextEditingController poemIdController = TextEditingController();
  TextEditingController newOwnerController = TextEditingController();
  String poemDetails = "";

  // Configuration
  final String privateKey = 'dc50e7d15fc7a35ed046e5d2c5151da2bb9a9fd427b2b00ba7db891dd11d0070';
  final EthereumAddress contractAddress = EthereumAddress.fromHex('0x416FE8F4A6FdBF588F3b4702d0d32C5e4c348E70');
  final String rpcUrl = 'https://eth-sepolia.g.alchemy.com/v2/12XGfHBxSlD1jXzb0IEkVHuz0SLn4t4Q';

  @override
  void initState() {
    super.initState();
    initializeWeb3();
  }

  Future<void> initializeWeb3() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      // Initialize Web3 client
      client = Web3Client(rpcUrl, Client());
      credentials = EthPrivateKey.fromHex(privateKey);
      await loadContract();
      
      setState(() {
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Failed to initialize Web3: ${e.toString()}';
      });
    }
  }

  Future<void> loadContract() async {
    const abiJson = '''[
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
            "indexed": true,
            "internalType": "address",
            "name": "newOwner",
            "type": "address"
          }
        ],
        "name": "OwnershipTransferred",
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
            "internalType": "string",
            "name": "title",
            "type": "string"
          },
          {
            "indexed": true,
            "internalType": "address",
            "name": "author",
            "type": "address"
          }
        ],
        "name": "PoemAdded",
        "type": "event"
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
            "internalType": "uint256",
            "name": "_poemId",
            "type": "uint256"
          }
        ],
        "name": "getPoem",
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
          }
        ],
        "stateMutability": "view",
        "type": "function"
      },
      {
        "inputs": [],
        "name": "poemCount",
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
            "name": "_poemId",
            "type": "uint256"
          },
          {
            "internalType": "address",
            "name": "_newOwner",
            "type": "address"
          }
        ],
        "name": "transferOwnership",
        "outputs": [],
        "stateMutability": "nonpayable",
        "type": "function"
      }
    ]''';

    contract = DeployedContract(
      ContractAbi.fromJson(abiJson, 'PoemStorage'),
      contractAddress,
    );
  }

  Future<void> addPoem() async {
    if (client == null || contract == null || credentials == null) {
      setState(() {
        errorMessage = 'Web3 client not initialized';
      });
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final title = titleController.text;
      final ipfsHash = ipfsHashController.text;

      if (title.isEmpty || ipfsHash.isEmpty) {
        throw Exception('Title and IPFS Hash are required');
      }

      final function = contract!.function('addPoem');
      await client!.sendTransaction(
        credentials!,
        Transaction.callContract(
          contract: contract!,
          function: function,
          parameters: [title, ipfsHash],
        ),
        chainId: 11155111,
      );

      setState(() {
        titleController.clear();
        ipfsHashController.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Poem added successfully: $title')),
      );
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to add poem: ${e.toString()}';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> getPoem() async {
    if (client == null || contract == null) {
      setState(() {
        errorMessage = 'Web3 client not initialized';
      });
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = '';
      poemDetails = '';
    });

    try {
      final poemId = BigInt.tryParse(poemIdController.text);
      if (poemId == null) {
        throw Exception('Invalid poem ID');
      }

      final function = contract!.function('getPoem');
      final result = await client!.call(
        contract: contract!,
        function: function,
        params: [poemId],
      );

      setState(() {
        poemDetails = '''
          Title: ${result[0]}
          IPFS Hash: ${result[1]}
          Author: ${result[2]}
          Timestamp: ${DateTime.fromMillisecondsSinceEpoch(result[3].toInt() * 1000)}
        ''';
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to retrieve poem: ${e.toString()}';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> transferOwnership() async {
    if (client == null || contract == null || credentials == null) {
      setState(() {
        errorMessage = 'Web3 client not initialized';
      });
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final poemId = BigInt.tryParse(poemIdController.text);
      if (poemId == null) {
        throw Exception('Invalid poem ID');
      }

      final newOwnerAddress = newOwnerController.text;
      if (!newOwnerAddress.startsWith('0x') || newOwnerAddress.length != 42) {
        throw Exception('Invalid Ethereum address');
      }

      final function = contract!.function('transferOwnership');
      await client!.sendTransaction(
        credentials!,
        Transaction.callContract(
          contract: contract!,
          function: function,
          parameters: [poemId, EthereumAddress.fromHex(newOwnerAddress)],
        ),
        chainId: 11155111,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ownership transferred successfully')),
      );
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to transfer ownership: ${e.toString()}';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    client?.dispose();
    titleController.dispose();
    ipfsHashController.dispose();
    poemIdController.dispose();
    newOwnerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('PoemStorage DApp')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (isLoading)
              Center(child: CircularProgressIndicator()),
            if (errorMessage.isNotEmpty)
              Card(
                color: Colors.red[100],
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    errorMessage,
                    style: TextStyle(color: Colors.red[900]),
                  ),
                ),
              ),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Add New Poem',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        labelText: 'Poem Title',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 8),
                    TextField(
                      controller: ipfsHashController,
                      decoration: InputDecoration(
                        labelText: 'IPFS Hash',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: isLoading ? null : addPoem,
                      child: Text('Add Poem'),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Retrieve Poem',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: poemIdController,
                      decoration: InputDecoration(
                        labelText: 'Poem ID',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: isLoading ? null : getPoem,
                      child: Text('Retrieve Poem'),
                    ),
                    if (poemDetails.isNotEmpty) ...[
                      SizedBox(height: 16),
                      Card(
                        color: Colors.blue[50],
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(poemDetails),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Transfer Ownership',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: newOwnerController,
                      decoration: InputDecoration(
                        labelText: 'New Owner Address',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: isLoading ? null : transferOwnership,
                      child: Text('Transfer Ownership'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}