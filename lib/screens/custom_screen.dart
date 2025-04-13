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
  int _rating = 0;
  final TextEditingController reviewController = TextEditingController();
  final TextEditingController sectionController = TextEditingController();
  final TextEditingController rowController = TextEditingController();
  final TextEditingController seatController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadBackgroundImage();
  }

  Future<void> _loadBackgroundImage() async {
    try {
      final urlParams = Uri.base.queryParameters;
      final ticketBackground = urlParams['ct'];

      if (ticketBackground != null) {
        final ref = FirebaseStorage.instance.ref("images/$ticketBackground");
        final url = await ref.getDownloadURL();
        setState(() => _ticketBackground = NetworkImage(url));
      } else {
        setState(() => _ticketBackground = AssetImage(Constants.ticketBackImage));
      }
    } catch (e) {
      print("배경 이미지 로드 실패: $e");
      setState(() => _ticketBackground = AssetImage(Constants.ticketBackImage));
    }
  }

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
          child: Stack(
            children: [
              // 상단 버튼
              Positioned(
                top: 10,
                left: 10,
                child: IconButton(
                  icon: Icon(Icons.arrow_back, color: Colors.white, size: 30),
                  onPressed: () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => MainScreen()),
                  ),
                ),
              ),

              // 저장 버튼
              Positioned(
                top: 10,
                right: 10,
                child: FloatingActionButton(
                  onPressed: saveData,
                  backgroundColor: Colors.deepPurpleAccent,
                  foregroundColor: Colors.white,
                  elevation: 6,
                  mini: true,
                  child: Icon(Icons.save_rounded),
                ),
              ),

              // 메인 콘텐츠 (스크롤 가능)
              Positioned.fill(
                top: 100,  // 기존 70 → 100 (상단 여백 증가)
                bottom: 40, // 기존 70 → 40 (하단 여백 감소)
                child: SingleChildScrollView(
                  physics: BouncingScrollPhysics(),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // 평점 입력
                      _buildRatingSection(),
                      SizedBox(height: 30),

                      // 리뷰 입력
                      _buildReviewField(),
                      SizedBox(height: 30),

                      // 좌석 정보 입력
                      _buildSeatInfoSection(),
                    ],
                  ),
                ),
              ),

              // 하단 Photos 버튼 (고정 위치)
              Positioned(
                bottom: 20,
                left: MediaQuery.of(context).size.width * 0.5 - 60, // 너비 조정
                child: ElevatedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => PhotoScreen()),
                  ),
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(120, 40), // 기존 150x50 → 120x40
                    padding: EdgeInsets.symmetric(horizontal: 20),
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

  Widget _buildRatingSection() {
    return Wrap(
      spacing: 10,
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
    );
  }

  Widget _buildReviewField() {
    return Container(
      width: MediaQuery.of(context).size.width * 0.7, // 기존 0.8 → 0.7
      padding: EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(15),
      ),
      child: TextField(
        controller: reviewController,
        style: TextStyle(color: Colors.white),
        maxLines: 1, // 기존 3 → 1
        decoration: InputDecoration(
          hintText: "Write your review...",
          hintStyle: TextStyle(
            color: Colors.white70,
            fontSize: 14, // 폰트 크기 축소
          ),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildSeatInfoSection() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 40),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildSeatInput(sectionController, "Section"),
          _buildSeatInput(rowController, "Row"),
          _buildSeatInput(seatController, "Seat"),
        ],
      ),
    );
  }

  Widget _buildSeatInput(TextEditingController controller, String hint) {
    return Container(
      width: 80,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.transparent,
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
