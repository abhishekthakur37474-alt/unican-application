import 'package:flutter/material.dart';
import '../models/verification_case.dart';
import '../services/verification_store.dart';
import 'verification_widgets.dart';
import 'verification_confirmed_screen.dart';
import 'verification_residing_screen.dart';

class VerificationNeighborScreen extends StatefulWidget {
  final VerificationCase verificationCase;

  const VerificationNeighborScreen({super.key, required this.verificationCase});

  @override
  State<VerificationNeighborScreen> createState() =>
      _VerificationNeighborScreenState();
}

class _VerificationNeighborScreenState
    extends State<VerificationNeighborScreen> {
  final _n1Ctrl = TextEditingController();
  final _n2Ctrl = TextEditingController();
  String? _confirmedChoice;

  @override
  void initState() {
    super.initState();
    final c = widget.verificationCase;
    _n1Ctrl.text = c.neighbor1;
    _n2Ctrl.text = c.neighbor2;
    _confirmedChoice = c.neighborConfirmed == null
        ? null
        : (c.neighborConfirmed! ? 'Confirmed' : 'Not confirmed');
  }

  void _next() {
    if (_confirmedChoice == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select confirmed status')),
      );
      return;
    }

    final c = widget.verificationCase;
    c.neighbor1 = _n1Ctrl.text;
    c.neighbor2 = _n2Ctrl.text;
    c.neighborConfirmed = _confirmedChoice == 'Confirmed';

    VerificationStore.instance.saveDraft(c, c.neighborConfirmed! ? 4 : 5);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => c.neighborConfirmed!
            ? VerificationConfirmedScreen(verificationCase: c)
            : VerificationResidingScreen(verificationCase: c),
      ),
    );
  }

  @override
  void dispose() {
    _n1Ctrl.dispose();
    _n2Ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return VStepScaffold(
      title: 'Neighbour Check',
      onNext: _next,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          VLabeledField(label: '1st Neighbour Name & Address', controller: _n1Ctrl),
          VLabeledField(label: '2nd Neighbour Name & Address', controller: _n2Ctrl),
          VOptionGroup(
            label: 'Details shared by neighbours about applicant',
            options: const ['Confirmed', 'Not confirmed'],
            value: _confirmedChoice,
            onChanged: (v) => setState(() => _confirmedChoice = v),
          ),
        ],
      ),
    );
  }
}