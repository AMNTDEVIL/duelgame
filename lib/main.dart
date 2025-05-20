import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: DuelGame(),
    );
  }
}

class DuelGame extends StatefulWidget {
  const DuelGame({super.key});

  @override
  State<DuelGame> createState() => _DuelGameState();
}

class _DuelGameState extends State<DuelGame> {
  int playerHp = 100;
  int enemyHp = 100;
  int playerLevel = 1;
  int enemyLevel = 1;
  int playerDmg = 10;
  int enemyDmg = 10;
  bool isPlayerTurn = true;
  String message = '';
  bool isFlashingPlayer = false;
  bool isFlashingEnemy = false;

  late WebSocketChannel channel;

  @override
  void initState() {
    super.initState();

    channel = WebSocketChannel.connect(Uri.parse('ws://192.168.1.64:8080'));

    channel.stream.listen((msg) {
      if (!mounted) return;

      if (!isPlayerTurn) {
        // Ignore player attacks if it's not player's turn
        return;
      }

      int damage = 5; // default damage

      switch (msg) {
        case 'P': // Punch
          damage = 10;
          break;
        case 'F': // Fire
          damage = 20;
          break;
        case 'I': // Ice
          damage = 15;
          break;
        case 'W': // Wind
          damage = 12;
          break;
      }

      setState(() {
        enemyHp = max(0, enemyHp - damage);
        message = 'Player attacks with $msg for $damage damage!';
        isFlashingEnemy = true;
      });

      Future.delayed(const Duration(milliseconds: 500), () {
        if (!mounted) return;

        setState(() {
          isFlashingEnemy = false;
        });
      });

      isPlayerTurn = false;
      _fightTurn();
    });

    message = 'Player\'s Turn';
  }

  @override
  void dispose() {
    channel.sink.close();
    super.dispose();
  }

  void _fightTurn() async {
    if (playerHp <= 0 || enemyHp <= 0) {
      _handleWin();
      return;
    }

    if (!isPlayerTurn) {
      // Enemy attacks
      setState(() {
        playerHp = max(0, playerHp - enemyDmg);
        isFlashingPlayer = true;
        message = 'Enemy attacks for $enemyDmg damage!';
      });

      await Future.delayed(const Duration(milliseconds: 500));

      setState(() {
        isFlashingPlayer = false;
      });

      if (playerHp <= 0) {
        _handleWin();
        return;
      }

      // Switch back to player's turn
      setState(() {
        isPlayerTurn = true;
        message = 'Player\'s Turn - Send attack command!';
      });
    }
  }

  void _handleWin() {
    if (enemyHp <= 0) {
      setState(() {
        message = 'Player Wins! Level Up!';
        playerLevel++;
        playerHp = 100 + (playerLevel * 10);
        playerDmg += 2;

        enemyLevel = max(1, enemyLevel); 
        enemyHp = 100 + (enemyLevel * 10);
        enemyDmg = 10 + (enemyLevel - 1) * 2;

        isPlayerTurn = true;
      });
    } else if (playerHp <= 0) {
      setState(() {
        message = 'Enemy Wins! Level Up!';
        enemyLevel++;
        enemyHp = 100 + (enemyLevel * 10);
        enemyDmg += 2;

        playerLevel = max(1, playerLevel); 
        playerHp = 100 + (playerLevel * 10);
        playerDmg = 10 + (playerLevel - 1) * 2;

        isPlayerTurn = true;
      });
    }
  }

  Widget _buildCharacter(
    String label,
    int hp,
    int level,
    bool isFlashing,
    String asset,
  ) {
    return Column(
      children: [
        Text(
          '$label - Level $level',
          style: const TextStyle(color: Colors.white),
        ),
        const SizedBox(height: 5),
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          color: isFlashing ? Colors.red : Colors.transparent,
          padding: const EdgeInsets.all(8),
          child: Image.asset(asset, height: 100),
        ),
        const SizedBox(height: 5),
        LinearProgressIndicator(
          value: hp / (100 + (level - 1) * 10),
          minHeight: 10,
          backgroundColor: Colors.grey,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
        ),
        Text('HP: $hp', style: const TextStyle(color: Colors.white)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildCharacter(
                'Player',
                playerHp,
                playerLevel,
                isFlashingPlayer,
                'assets/warrior.png',
              ),
              const SizedBox(height: 20),
              Text(
                message,
                style: const TextStyle(color: Colors.yellow, fontSize: 18),
              ),
              const SizedBox(height: 20),
              _buildCharacter(
                'Enemy',
                enemyHp,
                enemyLevel,
                isFlashingEnemy,
                'assets/demon.png',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
