import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:faber_ticket_tkpt/screens/photo_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:faber_ticket_tkpt/services/firebase_service.dart';
import 'package:faber_ticket_tkpt/screens/main_screen.dart';
import 'package:faber_ticket_tkpt/utils/constants.dart';

class CustomScreen extends StatefulWidget {
  @override
  _CustomScreenState createState() => _CustomScreenState();
}

class _CustomScreenState extends State<CustomScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  ImageProvider? _ticketBackground;

  @override
  void initState() {
    super.initState();
    _loadBackgroundImage();
  }

  // 수정된 _loadBackgroundImage()
  Future<void> _loadBackgroundImage() async {
    try {
      final urlParams = Uri.base.queryParameters;
      final ticketBackground = urlParams['ct'];

      if (ticketBackground != null) {
        final ref = FirebaseStorage.instance.ref("images/$ticketBackground");
        final url = await ref.getDownloadURL();
        setState(() => _ticketBackground = NetworkImage(url));
      } else {
        // 파라미터 없을 때 기본 이미지 적용
        setState(() => _ticketBackground = AssetImage(Constants.ticketBackImage));
      }
    } catch (e) {
      print("배경 이미지 로드 실패: $e");
      setState(() => _ticketBackground = AssetImage(Constants.ticketBackImage));
    }
  }




  int _rating = 0; // 평점
  final TextEditingController reviewController = TextEditingController();
  final TextEditingController sectionController = TextEditingController();
  final TextEditingController rowController = TextEditingController();
  final TextEditingController seatController = TextEditingController();

  Future<void> saveData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not logged in');

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('reviews')
          .add({
        'rating': _rating,
        'review': reviewController.text,
        'section': sectionController.text,
        'row': rowController.text,
        'seat': seatController.text,
        'timestamp': FieldValue.serverTimestamp()
      });
    } catch (e) {
      print('Error: $e');
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: _ticketBackground!,
            fit: BoxFit.cover,
            alignment: Alignment.topCenter, // 배경 이미지를 화면 상단에 맞춤
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Back 버튼 (화면 좌측 상단)
              Positioned(
                top: 5, // 화면 최상단에 위치하도록 조정
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
              // Save 버튼 (화면 우측 상단)
              Positioned(
                top: 17, // 화면 최상단에 위치하도록 조정
                right: 29,
                child: FloatingActionButton(
                  onPressed: saveData,
                  backgroundColor: Colors.deepPurpleAccent,
                  foregroundColor: Colors.white,
                  elevation: 6,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Container(
                    width: 30,
                    height: 30,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.rectangle,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.3),
                          spreadRadius: 2,
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        )
                      ],
                    ),
                    child: Icon(Icons.save_rounded, size: 28),
                  ),
                ),
              ),
              // Rate (평점 기능)
              Positioned(
                top: MediaQuery.of(context).size.height * 0.6, // 이미지 위치를 아래로 이동(숫자 크게하면 아래로)
                left: MediaQuery.of(context).size.width * 0.5 - 90, // 이미지 위치 조정(- 뒤 숫자 줄이면 우측으로)
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly, // 이미지 간격 조정
                  children: List.generate(5, (index) {
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          if (index < _rating) {
                            _rating = index + 1;
                          } else if (index == _rating) {
                            _rating = index;
                          } else {
                            _rating = index + 1;
                          }
                        });
                      },
                      child: Image.asset(
                        index < _rating ? Constants.petalFullImage : Constants.petalEmptyImage,
                        width: 40, // 이미지 크기 조정
                        height: 40,
                      ),
                    );
                  }).map((child) => [child, SizedBox(width: 10)]).expand((pair) => pair).toList(),
                ),
              ),
              // Review 입력
              Positioned(
                top: MediaQuery.of(context).size.height * 0.71, // 이미지 상의 "Review" 위치
                left: MediaQuery.of(context).size.width * 0.5 - 90,
                child: SizedBox(
                  width: 300,
                  child: TextField(
                    controller: reviewController,
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "Write your review",
                      hintStyle: TextStyle(color: Colors.white),
                      border: InputBorder.none, // 밑줄 제거
                    ),
                  ),
                ),
              ),
              // Section, Row, Seat 입력
              Positioned(
                top: MediaQuery.of(context).size.height * 0.82, // 이미지 상의 "Section", "Row", "Seat" 위치
                left: MediaQuery.of(context).size.width * 0.1,
                right: MediaQuery.of(context).size.width * 0.1,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(left: 4.9),
                      child: SizedBox(
                        width: MediaQuery.of(context).size.width * 0.16,
                        child: TextField(
                          textAlign: TextAlign.center, // 텍스트 중간 정렬
                          controller: sectionController,
                          style: TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: "Section",
                            hintStyle: TextStyle(color: Colors.grey),
                            border: InputBorder.none, // 밑줄 제거
                          ),
                        ),
                      ),
                    ),
                    // SizedBox(width: 20,),
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.16,
                      child: TextField(
                        textAlign: TextAlign.center, // 텍스트 중간 정렬
                        controller: rowController,
                        style: TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: "Row",
                          hintStyle: TextStyle(color: Colors.grey),
                          border: InputBorder.none, // 밑줄 제거
                        ),
                      ),
                    ),
                    // SizedBox(width: 20,),
                    Padding(
                      padding: EdgeInsets.only(right: 4.9),
                      child: SizedBox(
                        width: MediaQuery.of(context).size.width * 0.16,
                        child: TextField(
                          textAlign: TextAlign.center, // 텍스트 중간 정렬
                          controller: seatController,
                          style: TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: "Seat",
                            hintStyle: TextStyle(color: Colors.grey),
                            border: InputBorder.none, // 밑줄 제거
                          ),
                        ),
                      ),
                    ),
                    // 기존 코드 하단에 추가
                    Positioned(
                      bottom: 30,
                      left: MediaQuery.of(context).size.width * 0.5 - 60,
                      child: ElevatedButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => PhotoScreen()),
                        ),
                        style: ElevatedButton.styleFrom(
                          minimumSize: Size(120, 50),
                          padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                          backgroundColor: Colors.purpleAccent,
                        ),
                        child: Text('Photos'),
                      ),
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
