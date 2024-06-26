import 'dart:developer';
import 'package:rupify/Src/requirements.dart';
import 'package:http/http.dart' as http;


class ScanPageFunctions{
  MobileScannerController controller = MobileScannerController();
  UserModelPrimary user;

  void makePayment(context, String? data) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );
    if (data!.isNotEmpty) {
      List<String> list = data.replaceAll('[', '').replaceAll(']', '').split(',').map((element) => element.trim()).toList();
      List<String> noteWithoutPurpose = [];
      List<int> purposeOfEachNote = [];
      for (dynamic note in list) {
        noteWithoutPurpose.add(note.split("::")[0]);
        purposeOfEachNote.add(int.parse(note.split("::")[1]));
        //TODO Purpose Check
      }
      for(int purpose in purposeOfEachNote){
        if(user.userData["purpose"].contains(purpose)){
          //Pass
        }else{
          Navigator.pop(context);
          AwesomeDialog(
            context: context,
            dialogType: DialogType.ERROR,
            animType: AnimType.RIGHSLIDE,
            title: 'Payment Failed',
            desc: 'You Dont Have Permission to Scan this Specific Purpose of $purpose',
            btnOkOnPress: () {
              Navigator.pop(context);
            },
            btnOkColor: Colors.red,

          ).show();
          return;
        }
      }
      String name = "Unknown";
      final response0 = await http.post(
        Uri.parse(transferAPI),
        headers: {"Content-Type": "application/json"},
        body: json.encode({"note_list": noteWithoutPurpose, "shopkeeper_aadhar": user.aadharNumber}),
      );
      final response11 = await http.post(
        Uri.parse(getValAPI),
        headers: {"Content-Type": "application/json"},
        body: json.encode({"note": noteWithoutPurpose[0]}),
      );
      if(response11.statusCode == 200){
        name = json.decode(response11.body)["name"];
      }
      List<dynamic> newNoteList = json.decode(response0.body)["notes"];
      if (response0.statusCode == 406) {
        String data = "";
        for (dynamic note in newNoteList) {
          final responseGetValueOfNewNote = await http.post(
            Uri.parse(getValAPI),
            headers: {"Content-Type": "application/json"},
            body: json.encode({"note": note}),
          );
          data += "\n";
          data+=responseGetValueOfNewNote.body;
        }
        Navigator.pop(context);
        AwesomeDialog(
          context: context,
          dialogType: DialogType.ERROR,
          animType: AnimType.RIGHSLIDE,
          title: 'Payment Failed',
          desc: 'User Does Not Have Ownership Of Following Notes:$data',
          btnOkOnPress: () {
            Navigator.pop(context);
          },
          btnOkColor: Colors.red,

        ).show();
        //TODO User have not ownership of following notes that are in new note list
      } else {

        int totalMoney = 0;
        for (dynamic note in newNoteList) {
          final responseGetValueOfNewNote = await http.post(
            Uri.parse(getValAPI),
            headers: {"Content-Type": "application/json"},
            body: json.encode({"note": note}),
          );
          int amt = int.parse(responseGetValueOfNewNote.body);
          note = note+"::0";
          user.noteData[note] = amt;
          user.history[note] = amt;
          totalMoney += amt;
        }
        Navigator.pop(context);
        print("showing Dialoge");
        AwesomeDialog(
          context: context,
          dialogType: DialogType.SUCCES,
          animType: AnimType.RIGHSLIDE,
          title: 'Payment Successful',
          desc: 'Recieved ₹$totalMoney from $name',
          btnOkOnPress: () {
            Navigator.pop(context);
          },

        ).show();
        print("Done Dialogue");
      }
    }
  }

  void scanImageFromGallery(context) async{
    final ImagePicker picker = ImagePicker();
    // Pick an image
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
    );
    if (image != null) {
      if (await controller.analyzeImage(image.path)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Barcode found!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No barcode found!'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  ScanPageFunctions({required this.controller,required this.user});
}