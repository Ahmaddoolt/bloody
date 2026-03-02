import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PriorityRequestCard extends StatefulWidget {
  const PriorityRequestCard({super.key});

  @override
  State<PriorityRequestCard> createState() => _PriorityRequestCardState();
}

class _PriorityRequestCardState extends State<PriorityRequestCard> {
  String _status = 'none'; // none, pending, high, rejected
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _fetchStatus();
  }

  Future<void> _fetchStatus() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    final data = await Supabase.instance.client
        .from('profiles')
        .select('priority_status')
        .eq('id', userId)
        .single();

    if (mounted) setState(() => _status = data['priority_status'] ?? 'none');
  }

  Future<void> _requestPriority() async {
    setState(() => _loading = true);
    final userId = Supabase.instance.client.auth.currentUser!.id;

    await Supabase.instance.client
        .from('profiles')
        .update({'priority_status': 'pending'}).eq('id', userId);

    if (mounted)
      setState(() {
        _status = 'pending';
        _loading = false;
      });
  }

  @override
  Widget build(BuildContext context) {
    Color color = Colors.blue;
    String text = "Request Priority";
    IconData icon = Icons.priority_high;
    VoidCallback? onPressed = _requestPriority;

    if (_status == 'pending') {
      color = Colors.orange;
      text = "Review Pending";
      icon = Icons.hourglass_top;
      onPressed = null;
    } else if (_status == 'high') {
      color = Colors.green;
      text = "High Priority Active";
      icon = Icons.check_circle;
      onPressed = null;
    }

    return Card(
      color: color.withOpacity(0.1),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withOpacity(0.3)),
      ),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(text, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
        subtitle: const Text("Get faster matches if your case is urgent."),
        trailing: _loading
            ? const SizedBox(
                width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
            : onPressed == null
                ? null
                : ElevatedButton(
                    onPressed: onPressed,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: color, foregroundColor: Colors.white),
                    child: const Text("Request"),
                  ),
      ),
    );
  }
}
