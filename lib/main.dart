// lib/main.dart
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

void main() {
  runApp(const SnakeApp());
}

class SnakeApp extends StatelessWidget {
  const SnakeApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cobra Run',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
        useMaterial3: false,
      ),
      home: const SnakeGamePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

enum Direction { up, down, left, right }

class SnakeGamePage extends StatefulWidget {
  const SnakeGamePage({super.key});

  @override
  State<SnakeGamePage> createState() => _SnakeGamePageState();
}

class _SnakeGamePageState extends State<SnakeGamePage> {
  // Grid configuration
  static const int rows = 20;
  static const int cols = 20;
  static const int totalCells = rows * cols;

  // Game state
  late List<int> snake; // indices on grid
  late int food; // index on grid
  Direction direction = Direction.right;
  Timer? gameTimer;
  Duration speed = const Duration(milliseconds: 200);
  bool isRunning = false;
  bool isGameOver = false;
  int score = 0;
  final Random _rand = Random();

  @override
  void initState() {
    super.initState();
    _initNewGame();
  }

  @override
  void dispose() {
    gameTimer?.cancel();
    super.dispose();
  }

  void _initNewGame() {
    snake = [cols * (rows ~/ 2) + (cols ~/ 2) - 1, cols * (rows ~/ 2) + (cols ~/ 2)];
    direction = Direction.right;
    food = _randomFreeCell();
    isRunning = false;
    isGameOver = false;
    score = 0;
    gameTimer?.cancel();
    setState(() {});
  }

  int _randomFreeCell() {
    final free = List<int>.generate(totalCells, (i) => i)..removeWhere((i) => snake.contains(i));
    return free[_rand.nextInt(free.length)];
  }

  void _startGame() {
    if (isRunning) return;
    isRunning = true;
    isGameOver = false;
    gameTimer = Timer.periodic(speed, (_) => _update());
    setState(() {});
  }

  void _pauseGame() {
    isRunning = false;
    gameTimer?.cancel();
    setState(() {});
  }

  void _restartGame() {
    _initNewGame();
    _startGame();
  }

  void _update() {
    if (!isRunning) return;
    final newHead = _getNextHeadIndex(snake.last, direction);

    // Collision with walls
    if (_isOutOfBounds(snake.last, direction) || snake.contains(newHead)) {
      _gameOver();
      return;
    }

    // Move snake
    snake.add(newHead);

    // Check food eaten
    if (newHead == food) {
      score += 10;
      // generate new food
      if (snake.length == totalCells) {
        // Won the game (filled board)
        _gameOver(won: true);
        return;
      }
      food = _randomFreeCell();
      // optionally increase speed as score grows:
      if (speed.inMilliseconds > 60 && score % 50 == 0) {
        speed = Duration(milliseconds: (speed.inMilliseconds * 0.9).floor());
        gameTimer?.cancel();
        gameTimer = Timer.periodic(speed, (_) => _update());
      }
    } else {
      // remove tail
      snake.removeAt(0);
    }
    setState(() {});
  }

  int _getNextHeadIndex(int currentHead, Direction dir) {
    final row = currentHead ~/ cols;
    final col = currentHead % cols;
    int newRow = row;
    int newCol = col;
    switch (dir) {
      case Direction.up:
        newRow = row - 1;
        break;
      case Direction.down:
        newRow = row + 1;
        break;
      case Direction.left:
        newCol = col - 1;
        break;
      case Direction.right:
        newCol = col + 1;
        break;
    }
    return newRow * cols + newCol;
  }

  bool _isOutOfBounds(int headIndex, Direction dir) {
    final row = headIndex ~/ cols;
    final col = headIndex % cols;
    switch (dir) {
      case Direction.up:
        return row - 1 < 0;
      case Direction.down:
        return row + 1 >= rows;
      case Direction.left:
        return col - 1 < 0;
      case Direction.right:
        return col + 1 >= cols;
    }
  }

  void _gameOver({bool won = false}) {
    isRunning = false;
    isGameOver = true;
    gameTimer?.cancel();
    setState(() {});
    final title = won ? 'You Win!' : 'Game Over';
    Future.delayed(const Duration(milliseconds: 200), () {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          title: Text(title),
          content: Text('Score: $score'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _initNewGame();
              },
              child: const Text('Exit'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _restartGame();
              },
              child: const Text('Play Again'),
            ),
          ],
        ),
      );
    });
  }

  // Input handling - swipes
  void _onVerticalDragUpdate(DragUpdateDetails details) {
    final dy = details.delta.dy;
    if (dy < -6 && direction != Direction.down) {
      direction = Direction.up;
    } else if (dy > 6 && direction != Direction.up) {
      direction = Direction.down;
    }
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    final dx = details.delta.dx;
    if (dx < -6 && direction != Direction.right) {
      direction = Direction.left;
    } else if (dx > 6 && direction != Direction.left) {
      direction = Direction.right;
    }
  }

  Widget _buildGrid() {
    // Use GridView.count to build the grid cells.
    return AspectRatio(
      aspectRatio: cols / rows,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[800]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
          ),
          itemBuilder: (context, index) {
            Color cellColor = Colors.grey[900]!;
            if (snake.contains(index)) {
              // Head vs body color
              cellColor = index == snake.last ? Colors.greenAccent : Colors.green;
            } else if (index == food) {
              cellColor = Colors.redAccent;
            }
            return Container(
              margin: const EdgeInsets.all(1),
              decoration: BoxDecoration(
                color: cellColor,
                borderRadius: BorderRadius.circular(2),
              ),
            );
          },
          itemCount: totalCells,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cobar Run'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(isRunning ? Icons.pause : Icons.play_arrow),
            onPressed: () {
              if (isRunning) {
                _pauseGame();
              } else {
                if (isGameOver) {
                  _initNewGame();
                }
                _startGame();
              }
            },
            tooltip: isRunning ? 'Pause' : 'Start',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _restartGame,
            tooltip: 'Restart',
          ),
        ],
      ),
      body: SafeArea(
        child: GestureDetector(
          onVerticalDragUpdate: _onVerticalDragUpdate,
          onHorizontalDragUpdate: _onHorizontalDragUpdate,
          onTap: () {
            // tap toggles pause/start
            if (isRunning) {
              _pauseGame();
            } else {
              _startGame();
            }
          },
          child: Column(
            children: [
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: Row(
                  children: [
                    Text('Score: $score', style: const TextStyle(fontSize: 18)),
                    const Spacer(),
                    Text(isGameOver ? 'Game Over' : (isRunning ? 'Playing' : 'Paused'),
                        style: const TextStyle(fontSize: 16)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Center(
                  child: FractionallySizedBox(
                    widthFactor: 0.95,
                    heightFactor: 0.95,
                    child: _buildGrid(),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Simple on-screen controls for desktop / accessibility
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 8),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _controlButton(Icons.arrow_upward, () {
                          if (direction != Direction.down) direction = Direction.up;
                          if (!isRunning) setState(() {});
                        }),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _controlButton(Icons.arrow_back, () {
                          if (direction != Direction.right) direction = Direction.left;
                          if (!isRunning) setState(() {});
                        }),
                        const SizedBox(width: 18),
                        _controlButton(Icons.menu, () {
                          // center - pause/start
                          if (isRunning) _pauseGame();
                          else _startGame();
                        }),
                        const SizedBox(width: 18),
                        _controlButton(Icons.arrow_forward, () {
                          if (direction != Direction.left) direction = Direction.right;
                          if (!isRunning) setState(() {});
                        }),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _controlButton(Icons.arrow_downward, () {
                          if (direction != Direction.up) direction = Direction.down;
                          if (!isRunning) setState(() {});
                        }),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
              const SizedBox(height: 6),
            ],
          ),
        ),
      ),
    );
  }

  Widget _controlButton(IconData icon, VoidCallback onTap) {
    return SizedBox(
      width: 52,
      height: 52,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: onTap,
        child: Icon(icon, size: 26),
      ),
    );
  }
}
