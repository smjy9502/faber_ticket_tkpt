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
            alignment: Alignment.topCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // 상단 버튼 그룹 (기존 위치 유지)
              Stack(
                children: [
                  Positioned(
                    top: 5,
                    left: 20,
                    child: IconButton(
                      icon: Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => MainScreen()),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 17,
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
                        child: Icon(Icons.save_rounded, size: 28),
                      ),
                    ),
                  ),
                ],
              ),

              // 메인 콘텐츠 영역 (기존 위치 유지)
              Expanded(
                child: SingleChildScrollView(
                  child: Stack(
                    children: [
                      // 평점 입력
                      Positioned(
                        top: MediaQuery.of(context).size.height * 0.6,
                        left: MediaQuery.of(context).size.width * 0.5 - 90,
                        child: Row(
                          children: List.generate(5, (index) {
                            return GestureDetector(
                              onTap: () => setState(() => _rating = index + 1),
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

                      // 리뷰 입력
                      Positioned(
                        top: MediaQuery.of(context).size.height * 0.71,
                        left: MediaQuery.of(context).size.width * 0.5 - 90,
                        child: SizedBox(
                          width: 300,
                          child: TextField(
                            controller: reviewController,
                            style: TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: "Write your review",
                              hintStyle: TextStyle(color: Colors.white70),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                      ),

                      // 좌석 정보 입력
                      Positioned(
                        top: MediaQuery.of(context).size.height * 0.82,
                        left: MediaQuery.of(context).size.width * 0.1,
                        right: MediaQuery.of(context).size.width * 0.1,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildSeatInput(sectionController, "Section"),
                            _buildSeatInput(rowController, "Row"),
                            _buildSeatInput(seatController, "Seat"),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 하단 Photos 버튼 (추가)
              Padding(
                padding: EdgeInsets.only(bottom: 30),
                child: ElevatedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => PhotoScreen()),
                  ),
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(150, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    backgroundColor: Colors.purpleAccent,
                  ),
                  child: Text('Photos'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

// 좌석 입력 필드 위젯 (기존 유지)
  Widget _buildSeatInput(TextEditingController controller, String hint) {
    return Container(
      width: 80,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(10),
      ),
      child: TextField(
        controller: controller,
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.white70),
          border: InputBorder.none,
        ),
      ),
    );
  }
}
