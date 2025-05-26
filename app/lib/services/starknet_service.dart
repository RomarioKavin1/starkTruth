import 'dart:io';

import 'package:starknet/starknet.dart';
import 'package:starknet_provider/starknet_provider.dart';
import 'dart:convert';

final provider = JsonRpcProvider(nodeUri: Uri.parse('https://starknet-sepolia.public.blastapi.io'));
const contractAddress = '0x027d49de9a9f841cdd36bba64b68736d170bf374b9e8a1c22c826406a17d20fa';
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
  return txHash;
}

// Helper: Compress string and convert to list of felt hex strings (0x...)
List<String> compressAndHexEncode(String input) {
  // Compress the input string using zlib
  final compressed = zlib.encode(utf8.encode(input));
  // Chunk into 31 bytes per felt
  List<String> felts = [];
  for (int i = 0; i < compressed.length; i += 31) {
    final chunk = compressed.sublist(i, i + 31 > compressed.length ? compressed.length : i + 31);
    final hexString = chunk.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    felts.add('0x$hexString');
  }
  return felts;
}

List<String> stringToFeltHexList(String input) {
  final bytes = input.codeUnits;
  List<String> felts = [];
  for (int i = 0; i < bytes.length; i += 31) {
    final chunk = bytes.sublist(i, i + 31 > bytes.length ? bytes.length : i + 31);
    if (chunk.isEmpty) {
      felts.add('0x0');
      continue;
    }
    final hexString = chunk.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    // Ensure hexString is not empty
    felts.add('0x${hexString.isEmpty ? '0' : hexString}');
  }
  // If input was empty, ensure at least one felt
  if (felts.isEmpty) felts.add('0x0');
  return felts;
}

// Helper: Serialize a Dart string to Cairo ByteArray calldata (length + bytes as felts)
List<Felt> stringToByteArrayFelts(String input) {
  final bytes = utf8.encode(input);
  return [
    Felt.fromInt(bytes.length),
    ...bytes.map((b) => Felt.fromInt(b)),
  ];
}

// Helper: Serialize int to Cairo u256 (low, high)
List<Felt> intToU256Felts(int value) {
  final low = value & ((1 << 128) - 1);
  final high = value >> 128;
  return [Felt.fromInt(low), Felt.fromInt(high)];
}

Future<void> associatePostDetails({
  required String secretHash,
  required String postId,
  required String title,
  required String description,
  required int duration,
}) async {
  // Extract filename from URL if it's a full URL
  String filename = postId;
  if (postId.contains('/')) {
    filename = postId.split('/').last;
  }

  // Properly serialize ByteArray and u256
  final postIdFelts = stringToByteArrayFelts(filename);
  final titleFelts = stringToByteArrayFelts(title);
  final descFelts = stringToByteArrayFelts(description);
  final durationFelts = intToU256Felts(duration);

  // Flatten calldata: secretHash, postIdFelts..., titleFelts..., descFelts..., durationFelts...
  final calldata = [
    Felt.fromHexString("0x20a807ce1a204867e63c7599c894722a509d5439ce70eb1ad0c0a874a5ed6a0"),
    ...postIdFelts,
    ...titleFelts,
    ...descFelts,
    ...durationFelts,
  ];
  print(calldata);
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
    print(response);
    final txHash = response.when(
      result: (result) => result.transaction_hash,
      error: (err) => throw Exception("Failed to execute associate_post_details"),
    );
    print('executed');
    await waitForAcceptance(transactionHash: txHash, provider: provider);
  } catch (e) {
    print(e);
  }
} 
