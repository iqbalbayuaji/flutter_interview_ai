enum Sender { user, ai }

class Message {
  final Sender sender;
  final String text;
  final DateTime time;

  Message({required this.sender, required this.text, DateTime? time})
      : time = time ?? DateTime.now();
}
