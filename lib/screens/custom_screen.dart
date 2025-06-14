import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:faber_ticket_tkpt/services/firebase_service.dart';
import 'package:faber_ticket_tkpt/screens/main_screen.dart';
import 'package:faber_ticket_tkpt/utils/constants.dart';
import 'dart:ui';
import 'dart:html' as html;
import 'error_screen.dart';

class CustomScreen extends StatefulWidget {
  @override
  _CustomScreenState createState() => _CustomScreenState();
}

class _CustomScreenState extends State<CustomScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  ImageProvider? _ticketBackground;

  int _rating = 0;
  final TextEditingController reviewController = TextEditingController();
  final TextEditingController sectionController = TextEditingController();
  final TextEditingController rowController = TextEditingController();
  final TextEditingController seatController = TextEditingController();

  double blurSigma = 12.0; // 줄이면 선명해진다.

  @override
  void initState() {
    super.initState();
    _loadBackgroundImage().then((_) {
      html.window.history.replaceState({}, '', '/custom');
    });
    _loadSavedData();
  }

  Future<void> _loadBackgroundImage() async {
    try {
      final storedParams = html.window.sessionStorage['params'];
      final urlParams = storedParams != null
          ? Uri(query: storedParams).queryParameters
          : Uri.base.queryParameters;
      final ticketBackground = urlParams['ct'];
      if (ticketBackground == null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => ErrorScreen()),
          );
        });
        return;
      }
      final ref = FirebaseStorage.instance.ref("images/$ticketBackground");
      final url = await ref.getDownloadURL();
      setState(() => _ticketBackground = NetworkImage(url));
    } catch (e) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => ErrorScreen()),
        );
      });
    }
  }

  Future<void> _loadSavedData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('reviews')
          .doc('current')
          .get();

      if (doc.exists) {
        setState(() {
          _rating = doc.data()!['rating'] ?? 0;
          reviewController.text = doc.data()!['review'] ?? '';
          sectionController.text = doc.data()!['section'] ?? '';
          rowController.text = doc.data()!['row'] ?? '';
          seatController.text = doc.data()!['seat'] ?? '';
        });
      }
    } catch (e) {
      print('데이터 불러오기 오류: $e');
    }
  }

  Future<void> saveData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not logged in');

      final currentData = {
        'rating': _rating,
        'review': reviewController.text,
        'section': sectionController.text,
        'row': rowController.text,
        'seat': seatController.text,
      };
      final prevDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('reviews')
          .doc('current')
          .get();

      if (!prevDoc.exists ||
          prevDoc.data()!.toString() != currentData.toString()) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('reviews')
            .doc('current')
            .set(currentData, SetOptions(merge: true));
      }
    } catch (e) {
      print('저장 오류: $e');
    }
  }

  // 입력 다이얼로그 (텍스트, 중앙 정렬, 최대 2줄 제한, 팝업 밖 터치 닫힘)
  Future<void> _showInputDialog({
    required String label,
    required TextEditingController controller,
    int? maxLines,
    TextInputType? keyboardType,
    String? hint,
    VoidCallback? onConfirm,
  }) async {
    final tempController = TextEditingController(text: controller.text);

    // 최대 2줄 제한 (review)
    List<TextInputFormatter> formatters = [];
    if (label.contains("리뷰") || label.toLowerCase().contains("review")) {
      formatters = [
        LengthLimitingTextInputFormatter(90),
        _MaxLinesEnforcer(2),
      ];
    }

    await showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black.withOpacity(0.25),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Material(
          color: Colors.transparent,
          child: Stack(
            children: [
              BackdropFilter(
                filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
                child: Container(),
              ),
              Center(
                child: Container(
                  width: 320,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 20,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 18),
                      TextField(
                        controller: tempController,
                        maxLines: maxLines ?? 1,
                        keyboardType: keyboardType,
                        autofocus: true,
                        textAlign: TextAlign.center,
                        textAlignVertical: TextAlignVertical.center,
                        style: TextStyle(color: Colors.white, fontSize: 18, height: 1.2),
                        decoration: InputDecoration(
                          hintText: hint ?? '',
                          hintStyle: TextStyle(color: Colors.white60),
                          border: InputBorder.none,
                          filled: false,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                        cursorColor: Colors.white,
                        inputFormatters: formatters,
                      ),
                      SizedBox(height: 24),
                      IconButton(
                        icon: Icon(Icons.check_circle_rounded, color: Colors.deepPurpleAccent, size: 40),
                        onPressed: () {
                          controller.text = tempController.text;
                          Navigator.of(context).pop();
                          if (onConfirm != null) onConfirm();
                        },
                        tooltip: "확인",
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // 평점(꽃잎) 입력 다이얼로그 (팝업 밖 터치 닫힘, 선택 즉시 반영)
  Future<void> _showRatingDialog() async {
    int tempRating = _rating;
    await showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black.withOpacity(0.25),
      pageBuilder: (context, animation, secondaryAnimation) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return Material(
              color: Colors.transparent,
              child: Stack(
                children: [
                  BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
                    child: Container(),
                  ),
                  Center(
                    child: Container(
                      width: 320,
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.07),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'My Score',
                            style: TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 18),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(5, (index) {
                              return GestureDetector(
                                onTap: () {
                                  setStateDialog(() {
                                    tempRating = index + 1;
                                  });
                                },
                                child: Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 4),
                                  child: Image.asset(
                                    index < tempRating
                                        ? Constants.petalFullImage
                                        : Constants.petalEmptyImage,
                                    width: 32,
                                    height: 32,
                                  ),
                                ),
                              );
                            }),
                          ),
                          SizedBox(height: 24),
                          IconButton(
                            icon: Icon(Icons.check_circle_rounded, color: Colors.deepPurpleAccent, size: 40),
                            onPressed: () {
                              setState(() => _rating = tempRating);
                              Navigator.of(context).pop();
                            },
                            tooltip: "확인",
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          if (_ticketBackground != null)
            Positioned.fill(
              child: Image(
                image: _ticketBackground!,
                fit: BoxFit.fill,
                // alignment: Alignment.topCenter,
              ),
            ),
          // Back 버튼
          Positioned(
            top: 5,
            left: 20,
            child: IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => MainScreen()),
                );
              },
            ),
          ),
          // Save 버튼
          Positioned(
            top: 11,
            right: 10,
            child: FloatingActionButton(
              onPressed: saveData,
              backgroundColor: Colors.grey.shade500,
              foregroundColor: Colors.white,
              elevation: 6,
              mini: true,
              child: Icon(Icons.save_rounded),
            ),
          ),
          // Rate (평점) - 팝업 호출, 위치 위로
          Positioned(
            top: MediaQuery.of(context).size.height * 0.58,
            left: MediaQuery.of(context).size.width * 0.5 - 90,
            child: GestureDetector(
              onTap: _showRatingDialog,
              child: Container(
                width: 240,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return Padding(
                      padding: EdgeInsets.symmetric(horizontal: 5),
                      child: Image.asset(
                        index < _rating
                            ? Constants.petalFullImage
                            : Constants.petalEmptyImage,
                        width: 40,
                        height: 40,
                      ),
                    );
                  }),
                ),
              ),
            ),
          ),
          // Review 위치 아래로 (0.675)
          Positioned(
            top: MediaQuery.of(context).size.height * 0.675,
            left: MediaQuery.of(context).size.width * 0.5 - 90,
            child: GestureDetector(
              onTap: () => _showInputDialog(
                label: "My Review",
                controller: reviewController,
                maxLines: 2,
                hint: "Write your review",
              ),
              child: Container(
                width: 200,
                padding: EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  reviewController.text.isEmpty ? "Write your review" : reviewController.text,
                  style: TextStyle(
                    color: reviewController.text.isEmpty ? Colors.white60 : Colors.white,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
          // Section, Row, Seat 위치 양쪽으로
          Positioned(
            top: MediaQuery.of(context).size.height * 0.812,
            left: MediaQuery.of(context).size.width * 0.12,
            right: MediaQuery.of(context).size.width * 0.12,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Section
                GestureDetector(
                  onTap: () => _showInputDialog(
                    label: "My Section",
                    controller: sectionController,
                    hint: "Section",
                  ),
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.16,
                    padding: EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      sectionController.text.isEmpty ? "Section" : sectionController.text,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: sectionController.text.isEmpty ? Colors.white60 : Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                // Row
                GestureDetector(
                  onTap: () => _showInputDialog(
                    label: "My Row",
                    controller: rowController,
                    hint: "Row",
                  ),
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.16,
                    padding: EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      rowController.text.isEmpty ? "Row" : rowController.text,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: rowController.text.isEmpty ? Colors.white60 : Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                // Seat
                GestureDetector(
                  onTap: () => _showInputDialog(
                    label: "My Seat",
                    controller: seatController,
                    hint: "Seat",
                  ),
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.16,
                    padding: EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      seatController.text.isEmpty ? "Seat" : seatController.text,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: seatController.text.isEmpty ? Colors.white60 : Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// 2줄 이상 입력 제한을 위한 커스텀 input formatter
class _MaxLinesEnforcer extends TextInputFormatter {
  final int maxLines;
  _MaxLinesEnforcer(this.maxLines);

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final lines = '\n'.allMatches(newValue.text).length + 1;
    if (lines > maxLines) {
      return oldValue;
    }
    return newValue;
  }
}
