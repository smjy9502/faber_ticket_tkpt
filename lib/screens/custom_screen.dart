import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:faber_ticket_tkpt/services/firebase_service.dart';
import 'package:faber_ticket_tkpt/screens/main_screen.dart';
import 'package:faber_ticket_tkpt/screens/photo_screen.dart';


class CustomScreen extends StatefulWidget {
  @override
  _CustomScreenState createState() => _CustomScreenState();
}

class _CustomScreenState extends State<CustomScreen> with SingleTickerProviderStateMixin {
  final FirebaseService _firebaseService = FirebaseService();

  int _currentIndex = 1;
  late AnimationController _controller;
  bool _isFront = true;
  bool _showHint = true;

  DateTime? _selectedDate;
  String seatText = "";
  double _rate = 0.0;
  String reviewText = "";

  Timer? _debounceTimer;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500),
    );
    Future.delayed(Duration(seconds: 3), () {
      if (mounted) setState(() => _showHint = false);
    });
    _loadSavedData();
  }

  @override
  void dispose() {
    _controller.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadSavedData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final doc = await _firebaseService.getCustomData();
      if (doc != null) {
        setState(() {
          // date
          if (doc['date'] != null && doc['date'] is String && doc['date'].isNotEmpty) {
            _selectedDate = DateTime.tryParse(doc['date']);
          }
          seatText = doc['seat'] ?? '';
          _rate = (doc['rate'] ?? 0).toDouble();
          reviewText = doc['review'] ?? '';
        });
      }
    } catch (e) {
      print('데이터 불러오기 오류: $e');
    }
  }

  void _onAnyFieldChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(seconds: 1), () {
      _saveData();
    });
  }

  Future<void> _saveData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not logged in');
      setState(() => _isSaving = true);
      final currentData = {
        'date': _selectedDate?.toIso8601String() ?? '',
        'seat': seatText,
        'rate': _rate,
        'review': reviewText,
      };
      await _firebaseService.saveCustomData(currentData);
    } catch (e) {
      print('저장 오류: $e');
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void _flipCard() {
    if (_isFront) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
    setState(() => _isFront = !_isFront);
  }

  Future<void> _pickDateTime() async {
    DateTime now = DateTime.now();
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: ThemeData(
            colorScheme: ColorScheme.light(
              primary: Color(0xFF93BBDF),
              onPrimary: Colors.white,
              onSurface: Color(0xFF93BBDF),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: Color(0xFF93BBDF)),
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(now),
        builder: (context, child) {
          return Theme(
            data: ThemeData(
              colorScheme: ColorScheme.light(
                primary: Color(0xFF93BBDF),
                onPrimary: Colors.white,
                onSurface: Color(0xFF93BBDF),
              ),
              textButtonTheme: TextButtonThemeData(
                style: TextButton.styleFrom(foregroundColor: Color(0xFF93BBDF)),
              ),
            ),
            child: child!,
          );
        },
      );

      if (pickedTime != null) {
        setState(() {
          _selectedDate = DateTime(
              pickedDate.year, pickedDate.month, pickedDate.day,
              pickedTime.hour, pickedTime.minute
          );
        });
      }
    }
  }

  void _onNavTap(int index) async {
    if (index == _currentIndex) return;
    setState(() => _currentIndex = index);
    Widget? nextScreen;
    if (index == 0) {
      nextScreen = MainScreen();
    } else if (index == 2) {
      nextScreen = PhotoScreen();
    }
    if (nextScreen != null) {
      // 왼쪽/오른쪽 방향 애니메이션
      final isLeft = index < 1;
      await Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => nextScreen!,
          transitionsBuilder: (_, animation, __, child) {
            final begin = Offset(isLeft ? -1.0 : 1.0, 0.0);
            final end = Offset.zero;
            final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: Curves.ease));
            return SlideTransition(position: animation.drive(tween), child: child);
          },
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double verticalSpacing = MediaQuery.of(context).size.height * 0.03;
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFF5F5F5), Color(0xFFE0E0E0)],
                ),
              ),
            ),
          ),
          Positioned.fill(child: CustomPaint(painter: _NoisePainter())),
          SafeArea(
            child: Column(
              children: [
                SizedBox(height: verticalSpacing * 2.0),
                Expanded(
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: GestureDetector(
                      onTap: _flipCard,
                      child: AnimatedBuilder(
                        animation: _controller,
                        builder: (context, child) {
                          final angle = _controller.value * pi;
                          final isUnder = angle > pi / 2;
                          return Transform(
                            alignment: Alignment.center,
                            transform: Matrix4.identity()
                              ..setEntry(3, 2, 0.001)
                              ..rotateY(angle),
                            child: isUnder
                                ? Transform(
                              alignment: Alignment.center,
                              transform: Matrix4.identity()..rotateY(pi),
                              child: _buildBackCard(screenWidth),
                            )
                                : _buildFrontCard(screenWidth),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                SizedBox(height: verticalSpacing * 1.2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildMinimalIconButton(Icons.home, 0),
                    _buildMinimalIconButton(Icons.confirmation_number, 1),
                    _buildMinimalIconButton(Icons.camera_alt, 2),
                  ],
                ),
                SizedBox(height: verticalSpacing * 1.5),
              ],
            ),
          ),
          if (_isSaving)
            Positioned(
              top: 18,
              right: 60,
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.blueGrey),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFrontCard(double screenWidth) {
    return Container(
      width: screenWidth * 0.85,
      padding: EdgeInsets.all(8),
      decoration: _cardBoxDecoration(),
      child: AspectRatio(
        aspectRatio: 3 / 5,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Stack(
            children: [
              Positioned.fill(
                child: Image.asset(
                  'assets/images/pier.webp',
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                ),
              ),
              if (_showHint)
                Positioned(
                  bottom: 50,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Text(
                      "탭해서 뒤집어요 ↺",
                      style: TextStyle(
                        fontSize: screenWidth * 0.04,
                        color: Colors.white.withOpacity(0.85),
                        shadows: [Shadow(color: Colors.black.withOpacity(0.5), offset: Offset(1,1), blurRadius: 3)],
                      ),
                    ),
                  ),
                ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  color: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Center(
                    child: Text(
                      "@sumink_",
                      style: TextStyle(
                        fontSize: screenWidth * 0.04,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 1.0,
                        color: Colors.black.withOpacity(0.5),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackCard(double screenWidth) {
    return Container(
      width: screenWidth * 0.85,
      padding: EdgeInsets.all(8),
      decoration: _cardBoxDecoration(),
      child: AspectRatio(
        aspectRatio: 3 / 5,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Column(
            children: [
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _infoRow("DATE", _selectedDate != null
                            ? "${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2,'0')}-${_selectedDate!.day.toString().padLeft(2,'0')} "
                            "(${['Mon','Tue','Wed','Thu','Fri','Sat','Sun'][_selectedDate!.weekday-1]}) "
                            "${_selectedDate!.hour.toString().padLeft(2,'0')}:${_selectedDate!.minute.toString().padLeft(2,'0')}"
                            : "YYYY-MM-DD",
                            onTap: _pickDateTime
                        ),
                        Divider(color: Color(0xFF93BBDF), thickness: 1),
                        _infoRow("VENUE", "잠실실내체육관"),
                        Divider(color: Color(0xFF93BBDF), thickness: 1),
                        _seatInputRow(),
                        Divider(color: Color(0xFF93BBDF), thickness: 1),
                        _infoRowStars("RATE"),
                        Divider(color: Color(0xFF93BBDF), thickness: 1),
                        _castingRow("CASTING", ["SUNGJIN", "Young K", "WONPIL", "DOWOON"]),
                        Divider(color: Color(0xFF93BBDF), thickness: 1),
                        SizedBox(height: 8),
                        Text("REVIEW", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF93BBDF))),
                        SizedBox(height: 12),
                        TextField(
                          maxLines: null,
                          decoration: InputDecoration(
                            hintText: "리뷰를 입력하세요",
                            hintStyle: TextStyle(color: Color(0xFF93BBDF).withOpacity(0.5)),
                            border: InputBorder.none,
                            isCollapsed: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                          style: TextStyle(fontSize: 14, color: Color(0xFF93BBDF)),
                          controller: TextEditingController.fromValue(
                            TextEditingValue(
                              text: reviewText,
                              selection: TextSelection.collapsed(offset: reviewText.length),
                            ),
                          ),
                          onChanged: (value) {
                            setState(() {
                              reviewText = value;
                            });
                            _onAnyFieldChanged();
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Container(
                color: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Center(
                  child: Image.asset(
                    'assets/images/logo.webp',
                    height: screenWidth * 0.05 * 1.3,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _seatInputRow() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text("SEAT", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF93BBDF))),
          Container(
            width: 120,
            child: TextField(
              textAlign: TextAlign.right,
              decoration: InputDecoration(
                hintText: "좌석 입력",
                hintStyle: TextStyle(color: Color(0xFF93BBDF).withOpacity(0.5)),
                border: InputBorder.none,
                isCollapsed: true,
                contentPadding: EdgeInsets.zero,
              ),
              style: TextStyle(fontSize: 14, color: Color(0xFF93BBDF)),
              controller: TextEditingController.fromValue(
                TextEditingValue(
                  text: seatText,
                  selection: TextSelection.collapsed(offset: seatText.length),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  seatText = value;
                });
                _onAnyFieldChanged();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String title, String value, {VoidCallback? onTap}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF93BBDF))),
          GestureDetector(
            onTap: onTap,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: onTap != null ? Color(0xFF93BBDF).withOpacity(0.8) : Color(0xFF93BBDF),
                decoration: TextDecoration.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRowStars(String title) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF93BBDF))),
          Row(
            children: List.generate(5, (index) {
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _rate = index + 1.0;
                  });
                  _onAnyFieldChanged();
                },
                child: Icon(
                  index < _rate ? Icons.star : Icons.star_border,
                  color: Color(0xFF93BBDF),
                  size: 22,
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _castingRow(String title, List<String> members) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF93BBDF))),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: members.take(2).map((m) => _pill(m)).toList(),
              ),
              SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: members.skip(2).map((m) => _pill(m)).toList(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _pill(String text) {
    return Container(
      margin: EdgeInsets.only(left: 6),
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Color(0xFF93BBDF),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text, style: TextStyle(fontSize: 12, color: Colors.white)),
    );
  }

  BoxDecoration _cardBoxDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(3, 5))],
    );
  }

  Widget _buildMinimalIconButton(IconData icon, int index) {
    final bool isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => _onNavTap(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: isSelected ? Colors.lightBlue : Colors.black.withOpacity(0.3),
              size: MediaQuery.of(context).size.width * 0.075),
          SizedBox(height: 4),
          if (isSelected)
            Container(width: 14, height: 2,
                decoration: BoxDecoration(color: Colors.lightBlue, borderRadius: BorderRadius.circular(1))),
        ],
      ),
    );
  }
}

class _NoisePainter extends CustomPainter {
  final Random _random = Random();
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withOpacity(0.015)..blendMode = BlendMode.srcOver;
    for (int i = 0; i < 8000; i++) {
      final dx = _random.nextDouble() * size.width;
      final dy = _random.nextDouble() * size.height;
      canvas.drawCircle(Offset(dx, dy), 0.3, paint);
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
