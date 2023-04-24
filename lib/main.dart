import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '老虎机游戏',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: '老虎机游戏'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _score = 0;
  final List<NumberCell> _randomCells = List.generate(20, (index) => NumberCell(type: 1, value: 1));
  final _random = Random();
  bool _rolling = false;

  void _generateRandomNumbers() {
    setState(() {
      _rolling = true;
    });

    Future.delayed(const Duration(milliseconds: 500), () {
      setState(() {
        for (int i = 0; i < _randomCells.length; i++) {
          int type = _random.nextInt(2) + 1;
          int value = _random.nextInt(10) + 1;
          _randomCells[i] = NumberCell(type: type, value: value);
        }
        _score = _randomCells.fold(0, (sum, current) => sum + current.getScore());
        _rolling = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              '当前分数:',
            ),
            Text(
              '$_score',
              style: Theme.of(context).textTheme.headline4,
            ),
            const SizedBox(height: 50),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GridView.builder(
                itemCount: 20,
                shrinkWrap: true,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1,
                ),
                itemBuilder: (context, index) {
                  return Card(
                    color: _randomCells[index].getBackgroundColor() ?? Colors.blue[100],
                    child: Stack(
                      children: [
                        if (_randomCells[index].getBackgroundImage() != null)
                          Positioned.fill(
                            child: _randomCells[index].getBackgroundImage()!,
                          ),
                        Center(
                          child: _rolling
                              ? StreamBuilder<int>(
                            initialData: _randomCells[index].getScore(),
                            stream: Stream<int>.periodic(
                              const Duration(milliseconds: 50),
                                  (count) => _random.nextInt(10) + 1,
                            ).take(10),
                            builder: (context, snapshot) {
                              return Text(
                                snapshot.data.toString(),
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              );
                            },
                          )
                              : Text(
                            _randomCells[index].getDisplayText(),
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _generateRandomNumbers,
        tooltip: '随机生成数字',
        child: const Icon(Icons.shuffle),
      ),
    );
  }
}


abstract class CellEffect {
  const CellEffect();

  Widget applyEffect(BuildContext context, Widget child);
}
class ShakeEffect extends CellEffect {
  final AnimationController controller;

  const ShakeEffect({required this.controller});

  @override
  Widget applyEffect(BuildContext context, Widget child) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return Transform.translate(
          offset: Offset((1 - controller.value) * 5, 0),
          child: child,
        );
      },
      child: child,
    );
  }
}

class ColorTransitionEffect extends CellEffect {
  final AnimationController controller;

  const ColorTransitionEffect({required this.controller});

  @override
  Widget applyEffect(BuildContext context, Widget child) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        Color color = Color.lerp(Colors.white, Colors.yellow, controller.value)!;
        return ColorFiltered(colorFilter: ColorFilter.mode(color, BlendMode.modulate), child: child);
      },
      child: child,
    );
  }
}


abstract class Cell {
  String getDisplayText();
  int getScore();
  Color? getBackgroundColor();
  Widget? getBackgroundImage();
}

class NumberCell extends StatefulWidget implements Cell{
  final int type;
  final int value;

  NumberCell({required this.type, required this.value});
  @override
  String getDisplayText() {
    return type == 1 ? '${'\u4E00\u4E8C\u4E09\u56DB\u4E94\u516D\u4E03\u516B\u4E5D\u5341'[value - 1]}' : '$value';
  }

  @override
  int getScore() {
    return type == 1 ? value : -value;
  }

  @override
  Color? getBackgroundColor() {
    return null;
  }

  @override
  Widget? getBackgroundImage() {
    return null;
  }
  @override
  _NumberCellState createState() => _NumberCellState();
}

class _NumberCellState extends State<NumberCell> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _controller.reverse();
      }
    });
  }

  @override
  void didUpdateWidget(covariant NumberCell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.type != oldWidget.type || widget.value != oldWidget.value) {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String getDisplayText() {
    return widget.type == 1 ? '\u4E00\u4E8C\u4E09\u56DB\u4E94\u516D\u4E03\u516B\u4E5D\u5341'[widget.value - 1] : '${widget.value}';

  }

  CellEffect getEffect() {
    return widget.type == 1 ? ColorTransitionEffect(controller: _controller) : ShakeEffect(controller: _controller);
  }

  @override
  Color? getBackgroundColor() {
    return null;
  }

  @override
  Widget? getBackgroundImage() {
    return null;
  }  @override
  Widget build(BuildContext context) {
    return getEffect().applyEffect(context, Text(getDisplayText(), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)));
  }
}
