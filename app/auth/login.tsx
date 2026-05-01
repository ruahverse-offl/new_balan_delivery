import React, { useEffect, useState } from 'react';
import {
  ActivityIndicator,
  Alert,
  KeyboardAvoidingView,
  Platform,
  Pressable,
  ScrollView,
  StyleSheet,
  Text,
  TextInput,
  View,
} from 'react-native';
import FontAwesome from '@expo/vector-icons/FontAwesome';
import { LinearGradient } from 'expo-linear-gradient';
import { router } from 'expo-router';
import { SafeAreaView } from 'react-native-safe-area-context';

import { Theme } from '@/constants/theme';
import { useAuth } from '@/context/AuthContext';
import { HREF_DELIVERIES } from '@/lib/navigation';

/**
 * Delivery partner sign-in (same API and visual language as customer app login).
 */
export default function DeliveryLoginScreen() {
  const { login, isAuthenticated, loading } = useAuth();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [busy, setBusy] = useState(false);

  useEffect(() => {
    if (!loading && isAuthenticated) {
      router.replace(HREF_DELIVERIES);
    }
  }, [loading, isAuthenticated]);

  const onSubmit = async () => {
    setBusy(true);
    try {
      if (!email.trim()) {
        Alert.alert('Validation', 'Email is required.');
        return;
      }
      if (password.length < 1) {
        Alert.alert('Validation', 'Password is required.');
        return;
      }
      await login(email.trim(), password);
      router.replace(HREF_DELIVERIES);
    } catch (e) {
      Alert.alert('Could not sign in', e instanceof Error ? e.message : 'Something went wrong');
    } finally {
      setBusy(false);
    }
  };

  if (loading) {
    return null;
  }

  return (
    <SafeAreaView style={styles.safe} edges={['bottom']}>
      <KeyboardAvoidingView style={styles.flex} behavior={Platform.OS === 'ios' ? 'padding' : undefined}>
        <ScrollView contentContainerStyle={styles.scroll} keyboardShouldPersistTaps="handled">
          <LinearGradient colors={[...Theme.gradientHero]} style={styles.hero}>
            <Text style={styles.heroTitle}>Delivery partner</Text>
            <Text style={styles.heroSub}>Use the delivery account issued by the pharmacy.</Text>
          </LinearGradient>

          <View style={styles.card}>
            <TextInput
              style={styles.input}
              placeholder="Email"
              value={email}
              onChangeText={setEmail}
              autoCapitalize="none"
              keyboardType="email-address"
            />
            <View style={styles.passwordRow}>
              <TextInput
                style={styles.passwordInput}
                placeholder="Password"
                value={password}
                onChangeText={setPassword}
                secureTextEntry={!showPassword}
                autoCapitalize="none"
              />
              <Pressable
                style={styles.passwordToggle}
                onPress={() => setShowPassword((v) => !v)}
                hitSlop={8}
                accessibilityLabel={showPassword ? 'Hide password' : 'Show password'}
                accessibilityRole="button">
                <FontAwesome name={showPassword ? 'eye-slash' : 'eye'} size={20} color={Theme.gray500} />
              </Pressable>
            </View>

            <Pressable style={styles.primary} onPress={onSubmit} disabled={busy}>
              {busy ? (
                <ActivityIndicator color={Theme.white} />
              ) : (
                <Text style={styles.primaryText}>Sign in</Text>
              )}
            </Pressable>

            <Pressable style={styles.cancel} onPress={() => router.back()} disabled={busy}>
              <Text style={styles.cancelText}>Close</Text>
            </Pressable>
          </View>
        </ScrollView>
      </KeyboardAvoidingView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  safe: { flex: 1, backgroundColor: Theme.gray50 },
  flex: { flex: 1 },
  scroll: { padding: 16, paddingBottom: 40 },
  hero: { borderRadius: Theme.radiusLg, padding: 22, marginBottom: 16 },
  heroTitle: { fontSize: 24, fontWeight: '800', color: Theme.white },
  heroSub: { marginTop: 8, color: 'rgba(255,255,255,0.9)', fontSize: 14, lineHeight: 20 },
  card: {
    backgroundColor: Theme.white,
    borderRadius: 14,
    padding: 16,
    borderWidth: 1,
    borderColor: Theme.gray200,
  },
  input: {
    borderWidth: 1,
    borderColor: Theme.gray200,
    borderRadius: 10,
    padding: 12,
    marginBottom: 10,
    fontSize: 16,
    color: Theme.gray900,
  },
  passwordRow: {
    flexDirection: 'row',
    alignItems: 'center',
    borderWidth: 1,
    borderColor: Theme.gray200,
    borderRadius: 10,
    marginBottom: 10,
    paddingRight: 4,
  },
  passwordInput: {
    flex: 1,
    paddingVertical: 12,
    paddingLeft: 12,
    paddingRight: 8,
    fontSize: 16,
    color: Theme.gray900,
  },
  passwordToggle: {
    padding: 10,
    justifyContent: 'center',
    alignItems: 'center',
  },
  primary: {
    backgroundColor: Theme.accentBlue,
    paddingVertical: 14,
    borderRadius: 12,
    alignItems: 'center',
    marginTop: 4,
  },
  primaryText: { color: Theme.white, fontWeight: '800', fontSize: 16 },
  cancel: { marginTop: 12, alignItems: 'center' },
  cancelText: { color: Theme.gray500, fontWeight: '600' },
});
