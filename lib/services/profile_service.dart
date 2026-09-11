import 'package:bumble/services/supabase_service.dart';

Future<bool> isProfileComplete(String userId) async {
  final data = await supabase
      .from('profiles')
      .select('age, gender, bio')
      .eq('id', userId)
      .maybeSingle();

  if (data == null) return false;
  return data['age'] != null && data['gender'] != null;
}