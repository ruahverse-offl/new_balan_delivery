import React, { useCallback, useEffect, useState } from 'react';
import {
  ActivityIndicator,
  Alert,
  Modal,
  Pressable,
  ScrollView,
  Switch,
  Text,
  TextInput,
  View,
} from 'react-native';
import { SafeAreaView, useSafeAreaInsets } from 'react-native-safe-area-context';

import { profileStyles } from '@/constants/profileScreenStyles';
import { Theme } from '@/constants/theme';
import { useAuth } from '@/context/AuthContext';
import { useNotifications } from '@/context/NotificationContext';
import { changePassword, verifyCurrentPassword } from '@/services/auth';
import { updateUserProfile } from '@/services/users';

/**
 * Partner profile: edit contact details (password-gated) and change password; sign out.
 */
export default function DeliveryProfileScreen() {
  const insets = useSafeAreaInsets();
  const { user, token, logout, updateLocalUser } = useAuth();
  const {
    loading: notifLoading,
    enabled: notifEnabled,
    setEnabled: setNotifEnabled,
  } = useNotifications();
  const [notifSaving, setNotifSaving] = useState(false);
  const [name, setName] = useState('');
  const [email, setEmail] = useState('');
  const [phone, setPhone] = useState('');
  const [saving, setSaving] = useState(false);
  const [confirmOpen, setConfirmOpen] = useState(false);
  const [accountPassword, setAccountPassword] = useState('');

  const [currentPw, setCurrentPw] = useState('');
  const [newPw, setNewPw] = useState('');
  const [newPw2, setNewPw2] = useState('');
  const [pwBusy, setPwBusy] = useState(false);

  useEffect(() => {
    if (user) {
      setName(user.name || '');
      setEmail(user.email || '');
      setPhone(user.mobile_number ? String(user.mobile_number).replace(/\D/g, '') : '');
    }
  }, [user]);

  const hasEdits = () => {
    if (!user) return false;
    const digits = phone.replace(/\D/g, '');
    const origPhone = user.mobile_number ? String(user.mobile_number).replace(/\D/g, '') : '';
    return (
      name.trim() !== (user.name || '').trim() ||
      email.trim() !== (user.email || '').trim() ||
      digits !== origPhone
    );
  };

  const onRequestSave = () => {
    if (!hasEdits()) {
      Alert.alert('No changes', 'Update your details before saving.');
      return;
    }
    setAccountPassword('');
    setConfirmOpen(true);
  };

  const onConfirmSave = async () => {
    if (!user?.id || !token) return;
    if (!accountPassword.trim()) {
      Alert.alert('Password required', 'Enter your account password to save changes.');
      return;
    }
    setSaving(true);
    try {
      await verifyCurrentPassword((user.email || '').trim(), accountPassword);
      const digits = phone.replace(/\D/g, '');
      await updateUserProfile(user.id, {
        full_name: name.trim(),
        email: email.trim(),
        mobile_number: digits.length >= 10 ? digits.slice(-10) : undefined,
      });
      await updateLocalUser({
        name: name.trim(),
        email: email.trim(),
        mobile_number: digits.length >= 10 ? digits.slice(-10) : user.mobile_number,
      });
      setConfirmOpen(false);
      setAccountPassword('');
      Alert.alert('Saved', 'Your profile was updated.');
    } catch (e) {
      Alert.alert('Could not save', e instanceof Error ? e.message : 'Please try again.');
    } finally {
      setSaving(false);
    }
  };

  const onToggleNotifications = useCallback(
    async (next: boolean) => {
      if (notifSaving) return;
      setNotifSaving(true);
      try {
        await setNotifEnabled(next);
      } catch (e) {
        Alert.alert('Settings', e instanceof Error ? e.message : 'Could not update notification settings.');
      } finally {
        setNotifSaving(false);
      }
    },
    [notifSaving, setNotifEnabled],
  );

  const onChangePassword = async () => {
    if (!token) return;
    if (!currentPw.trim()) {
      Alert.alert('Validation', 'Enter your current password.');
      return;
    }
    if (newPw.length < 6) {
      Alert.alert('Validation', 'New password must be at least 6 characters.');
      return;
    }
    if (newPw !== newPw2) {
      Alert.alert('Validation', 'New passwords do not match.');
      return;
    }
    setPwBusy(true);
    try {
      await changePassword(token, currentPw, newPw);
      setCurrentPw('');
      setNewPw('');
      setNewPw2('');
      Alert.alert('Updated', 'Your password was changed.');
    } catch (e) {
      Alert.alert('Could not update', e instanceof Error ? e.message : 'Please try again.');
    } finally {
      setPwBusy(false);
    }
  };

  return (
    <SafeAreaView style={profileStyles.safe} edges={['left', 'right']}>
      <ScrollView contentContainerStyle={profileStyles.scroll} keyboardShouldPersistTaps="handled">
        <Text style={profileStyles.h1}>Profile</Text>
        <Text style={profileStyles.sub}>Your delivery partner account details.</Text>

        <View style={profileStyles.card}>
          <View style={{ flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', gap: 12 }}>
            <View style={{ flex: 1 }}>
              <Text style={[profileStyles.cardTitle, { marginBottom: 2 }]}>Push notifications</Text>
              <Text style={[profileStyles.hint, { marginBottom: 0 }]}>
                Get alerts for new assignments and order updates.
              </Text>
            </View>
            <Switch
              value={notifEnabled}
              onValueChange={onToggleNotifications}
              disabled={notifSaving || notifLoading}
              trackColor={{ false: Theme.gray300, true: Theme.primary }}
              thumbColor={Theme.white}
            />
          </View>
        </View>

        <View style={profileStyles.card}>
          <Text style={profileStyles.label}>Full name</Text>
          <TextInput style={profileStyles.input} value={name} onChangeText={setName} />
          <Text style={profileStyles.label}>Email</Text>
          <TextInput style={profileStyles.input} value={email} onChangeText={setEmail} autoCapitalize="none" />
          <Text style={profileStyles.label}>Mobile (10 digits)</Text>
          <TextInput style={profileStyles.input} value={phone} onChangeText={setPhone} keyboardType="phone-pad" />
          <Pressable style={profileStyles.primary} onPress={onRequestSave} disabled={saving}>
            {saving && !confirmOpen ? <ActivityIndicator color="#fff" /> : <Text style={profileStyles.primaryText}>Save changes</Text>}
          </Pressable>
        </View>

        <Text style={[profileStyles.label, { marginTop: 8, marginLeft: 2 }]}>Security</Text>
        <View style={profileStyles.card}>
          <Text style={profileStyles.label}>Current password</Text>
          <TextInput
            style={profileStyles.input}
            value={currentPw}
            onChangeText={setCurrentPw}
            secureTextEntry
            autoCapitalize="none"
          />
          <Text style={profileStyles.label}>New password</Text>
          <TextInput
            style={profileStyles.input}
            value={newPw}
            onChangeText={setNewPw}
            secureTextEntry
            autoCapitalize="none"
          />
          <Text style={profileStyles.label}>Confirm new password</Text>
          <TextInput
            style={profileStyles.input}
            value={newPw2}
            onChangeText={setNewPw2}
            secureTextEntry
            autoCapitalize="none"
          />
          <Pressable style={profileStyles.primary} onPress={onChangePassword} disabled={pwBusy}>
            {pwBusy ? <ActivityIndicator color="#fff" /> : <Text style={profileStyles.primaryText}>Update password</Text>}
          </Pressable>
        </View>

        <Pressable
          style={[profileStyles.outline, { marginTop: 8, borderColor: Theme.gray200 }]}
          onPress={() => {
            Alert.alert('Sign out', 'You will need to sign in again to see deliveries.', [
              { text: 'Cancel', style: 'cancel' },
              {
                text: 'Sign out',
                style: 'destructive',
                onPress: () => void logout(),
              },
            ]);
          }}>
          <Text style={[profileStyles.outlineText, { color: Theme.primaryDark }]}>Sign out</Text>
        </Pressable>
      </ScrollView>

      <Modal visible={confirmOpen} animationType="slide" transparent onRequestClose={() => setConfirmOpen(false)}>
        <Pressable
          style={{ flex: 1, backgroundColor: 'rgba(15,23,42,0.4)', justifyContent: 'flex-end' }}
          onPress={() => setConfirmOpen(false)}>
          <Pressable onPress={() => {}}>
            <SafeAreaView style={{ backgroundColor: 'transparent' }} edges={['bottom']}>
              <View style={[profileStyles.modalCard, { paddingBottom: Math.max(12, insets.bottom) }]}>
                <Text style={profileStyles.modalTitle}>Confirm with password</Text>
                <Text style={profileStyles.modalSub}>Enter your current account password to save profile changes.</Text>
                <Text style={profileStyles.label}>Password</Text>
                <TextInput
                  style={profileStyles.input}
                  value={accountPassword}
                  onChangeText={setAccountPassword}
                  secureTextEntry
                  autoCapitalize="none"
                />
                <View style={profileStyles.modalRow}>
                  <Pressable
                    style={[profileStyles.modalBtn, profileStyles.modalGhost]}
                    onPress={() => {
                      setConfirmOpen(false);
                      setAccountPassword('');
                    }}>
                    <Text style={profileStyles.outlineText}>Cancel</Text>
                  </Pressable>
                  <Pressable style={[profileStyles.modalBtn, profileStyles.primary]} onPress={onConfirmSave} disabled={saving}>
                    {saving ? <ActivityIndicator color="#fff" /> : <Text style={profileStyles.primaryText}>Save</Text>}
                  </Pressable>
                </View>
              </View>
            </SafeAreaView>
          </Pressable>
        </Pressable>
      </Modal>
    </SafeAreaView>
  );
}
