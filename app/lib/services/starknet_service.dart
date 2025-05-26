import 'package:starknet/starknet.dart';
import 'package:starknet_provider/starknet_provider.dart';

final provider = JsonRpcProvider(nodeUri: Uri.parse('https://starknet-sepolia.public.blastapi.io'));
const contractAddress = '0x01cac254acbcd5c2a68c3a5aa04b58466d6cb0e578a431c0f4a68c2790dff610';
const secretAccountAddress = "0x06Ca2a8a32DF51babaC26EC00e43357c18FcCEFE2C04320aa455F41508316d03";
const secretAccountPrivateKey = "0x022aece03eecb92ae673a4de2dbfe5f7d1af696f3e0a18c1238953c89b5ea9e0";
final signeraccount = getAccount(
  accountAddress: Felt.fromHexString(secretAccountAddress),
  privateKey: Felt.fromHexString(secretAccountPrivateKey),
  nodeUri: Uri.parse('https://starknet-sepolia.public.blastapi.io'),
);

Future<String> createPreSecret(String userWalletAddress) async {
  final signeraccount = getAccount(
  accountAddress: Felt.fromHexString(secretAccountAddress),
  privateKey: Felt.fromHexString(secretAccountPrivateKey),
  nodeUri: Uri.parse('https://starknet-sepolia.public.blastapi.io'),
);
  print(signeraccount.accountAddress);
  print("Calling create_pre_secret with: $userWalletAddress");
  final response = await signeraccount.execute(functionCalls: [
    FunctionCall(
      contractAddress: Felt.fromHexString(contractAddress),
      entryPointSelector: getSelectorByName("create_pre_secret"),
      calldata: [Felt.fromHexString(userWalletAddress)],
    ),
  ]);
  print("Response: $response");
  final txHash = response.when(
    result: (result) => result.transaction_hash,
    error: (err) {
      print("create_pre_secret error: $err");
      throw Exception("Failed to execute create_pre_secret: $err");
    },
  );

  // Wait for transaction to be accepted
  await waitForAcceptance(transactionHash: txHash, provider: provider);

  // Now fetch the receipt
  final receipt = await provider.getTransactionReceipt(Felt.fromHexString(txHash));
  final result = receipt.when(
    result: (r) => r,
    error: (err) => throw Exception("Failed to get receipt: $err"),
  );

  print(result.events[1].data);
  final secrethash=result.events[1].data?[2];
  return secrethash.toString();
}

Future<void> associatePostDetails({
  required String secretId,    // Changed from secretHash to match contract
  required String postId,      // decimal string
}) async {
  final calldata = [
    Felt.fromIntString(secretId),
    Felt.fromIntString(postId),
    Felt.fromInt(120),      // Low part of u256
    Felt.fromInt(0),            // High part of u256 (0 for small numbers)
  ];
  
  print("Calldata: $calldata");
  
  final signeraccount = getAccount(
    accountAddress: Felt.fromHexString(secretAccountAddress),
    privateKey: Felt.fromHexString(secretAccountPrivateKey),
    nodeUri: Uri.parse('https://starknet-sepolia.public.blastapi.io'),
  );
  
  try {
    final response = await signeraccount.execute(functionCalls: [
      FunctionCall(
        contractAddress: Felt.fromHexString(contractAddress),
        entryPointSelector: getSelectorByName("associate_post_details"),
        calldata: calldata,
      ),
    ]);
    
    print("associate complete");
    
    response.when(
      result: (result) {
        print("Transaction hash: ${result.transaction_hash}");
        return result.transaction_hash;
      },
      error: (err) {
        print("Error details: $err");
        throw Exception("Failed to execute associate_post_details: $err");
      },
    );
  } catch (e) {
    print("Exception caught: $e");
    rethrow;
  }
}