import 'package:supabase_flutter/supabase_flutter.dart';

// Neutral, global instance of Supabase Client to break circular dependencies
final supabase = Supabase.instance.client;
