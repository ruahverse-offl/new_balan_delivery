import React, { useCallback, useEffect, useState } from 'react';
import {
  ActivityIndicator,
  Alert,
  Modal,
  Pressable,
  ScrollView,
  StyleSheet,
  Text,
  TextInput,
  View,
} from 'react-native';
import { Stack, useLocalSearchParams, useRouter } from 'expo-router';
import { SafeAreaView } from 'react-native-safe-area-context';

import { profileStyles } from '@/constants/profileScreenStyles';
import { Theme } from '@/constants/theme';
import { useAuth } from '@/context/AuthContext';
import {
  actionButtonLabel,
  formatOrderStatusLabel,
  getAllowedNextStatusActions,
  type NextStatusAction,
} from '@/lib/orderLifecycle';
import { HREF_DELIVERIES } from '@/lib/navigation';
import { getOrderDetail, updateOrder, type OrderDetailResponse, type OrderItemRow } from '@/services/orders';

function formatAmount(v: string | number): string {
  const n = typeof v === 'string' ? parseFloat(v) : v;
  if (Number.isNaN(n)) return String(v);
  return `₹${n.toFixed(0)}`;
}

/**
 * Order detail + delivery lifecycle actions (same rules as web `getAllowedNextStatusActions`).
 */
export default function DeliveryOrderDetailScreen() {
  const { id: rawId } = useLocalSearchParams<{ id: string }>();
  const orderId = Array.isArray(rawId) ? rawId[0] : rawId;
  const router = useRouter();
  const { user, menuItems } = useAuth();

  const [detail, setDetail] = useState<OrderDetailResponse | null>(null);
  const [loading, setLoading] = useState(true);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const [returnModal, setReturnModal] = useState<{ action: NextStatusAction } | null>(null);
  const [returnReason, setReturnReason] = useState('');

  const load = useCallback(async () => {
    if (!orderId) return;
    setError(null);
    setLoading(true);
    try {
      const d = await getOrderDetail(orderId);
      setDetail(d);
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Could not load order');
      setDetail(null);
    } finally {
      setLoading(false);
    }
  }, [orderId]);

  useEffect(() => {
    void load();
  }, [load]);

  const order = detail?.order;
  const actions = order
    ? getAllowedNextStatusActions({
        order,
        menuItems,
        userId: user?.id ?? null,
        isAdminRole: false,
      })
    : [];

  const onAction = async (act: NextStatusAction) => {
    if (!orderId || !order) return;
    if (act.requires === 'return_reason') {
      setReturnReason('');
      setReturnModal({ action: act });
      return;
    }
    Alert.alert('Update status', `Set order to ${formatOrderStatusLabel(act.status)}?`, [
      { text: 'Cancel', style: 'cancel' },
      {
        text: 'Confirm',
        onPress: async () => {
          setBusy(true);
          try {
            const updated = await updateOrder(orderId, { order_status: act.status });
            setDetail((prev) =>
              prev ? { ...prev, order: { ...prev.order, ...updated, order_status: updated.order_status } } : prev,
            );
            Alert.alert('Done', 'Order status was updated.');
          } catch (e) {
            Alert.alert('Could not update', e instanceof Error ? e.message : 'Try again.');
          } finally {
            setBusy(false);
          }
        },
      },
    ]);
  };

  const confirmReturn = async () => {
    if (!orderId || !returnModal) return;
    const reason = returnReason.trim();
    if (!reason) {
      Alert.alert('Reason required', 'Please enter why the delivery could not be completed.');
      return;
    }
    setBusy(true);
    try {
      const updated = await updateOrder(orderId, {
        order_status: returnModal.action.status,
        return_reason: reason,
      });
      setReturnModal(null);
      setReturnReason('');
      setDetail((prev) =>
        prev ? { ...prev, order: { ...prev.order, ...updated, order_status: updated.order_status } } : prev,
      );
      Alert.alert('Done', 'Order marked as returned to store.');
    } catch (e) {
      Alert.alert('Could not update', e instanceof Error ? e.message : 'Try again.');
    } finally {
      setBusy(false);
    }
  };

  if (!orderId) {
    return (
      <SafeAreaView style={profileStyles.safe}>
        <Text style={profileStyles.msg}>Invalid order.</Text>
      </SafeAreaView>
    );
  }

  if (loading) {
    return (
      <SafeAreaView style={profileStyles.safe}>
        <Stack.Screen options={{ title: 'Order' }} />
        <View style={styles.centered}>
          <ActivityIndicator size="large" color={Theme.primary} />
        </View>
      </SafeAreaView>
    );
  }

  if (error || !detail || !order) {
    return (
      <SafeAreaView style={[profileStyles.safe, styles.pad]}>
        <Stack.Screen options={{ title: 'Order' }} />
        <Text style={profileStyles.msg}>{error || 'Order not found.'}</Text>
        <Pressable style={profileStyles.outline} onPress={() => router.replace(HREF_DELIVERIES)}>
          <Text style={profileStyles.outlineText}>Back to deliveries</Text>
        </Pressable>
      </SafeAreaView>
    );
  }

  const ref = (order.order_reference || '').trim() || order.id;

  return (
    <SafeAreaView style={[profileStyles.safe, styles.pad]} edges={['bottom']}>
      <Stack.Screen options={{ title: ref }} />
      <ScrollView contentContainerStyle={profileStyles.scroll} keyboardShouldPersistTaps="handled">
        <Text style={profileStyles.h1}>{ref}</Text>
        <Text style={profileStyles.sub}>{formatOrderStatusLabel(order.order_status)}</Text>

        <View style={profileStyles.card}>
          <Text style={profileStyles.label}>Customer</Text>
          <Text style={styles.body}>{order.customer_name || '—'}</Text>
          <Text style={styles.bodyMuted}>{order.customer_phone}</Text>
          <Text style={[profileStyles.label, { marginTop: 12 }]}>Address</Text>
          <Text style={styles.body}>{order.delivery_address}</Text>
          <Text style={[profileStyles.label, { marginTop: 12 }]}>Amount</Text>
          <Text style={styles.amount}>{formatAmount(order.final_amount)}</Text>
        </View>

        {actions.length > 0 ? (
          <>
            <Text style={[profileStyles.label, { marginLeft: 2 }]}>Your actions</Text>
            <View style={profileStyles.card}>
              {actions.map((act) => (
                <Pressable
                  key={act.status}
                  style={[styles.actionBtn, busy && styles.actionBtnDisabled]}
                  onPress={() => void onAction(act)}
                  disabled={busy}>
                  <Text style={styles.actionBtnText}>{actionButtonLabel(act)}</Text>
                </Pressable>
              ))}
            </View>
          </>
        ) : (
          <Text style={[profileStyles.hint, { marginBottom: 16 }]}>
            No actions available for this status, or this order is not assigned to you.
          </Text>
        )}

        <Text style={[profileStyles.label, { marginLeft: 2 }]}>Items</Text>
        <View style={profileStyles.card}>
          {(detail.items || []).length === 0 ? (
            <Text style={profileStyles.hint}>No line items.</Text>
          ) : (
            (detail.items || []).map((line: OrderItemRow) => (
              <View key={line.id} style={styles.lineRow}>
                <Text style={styles.lineName}>
                  {line.medicine_name || 'Item'}
                  {line.brand_name ? ` · ${line.brand_name}` : ''}
                </Text>
                <Text style={styles.lineMeta}>
                  ×{line.quantity} · {formatAmount(line.total_price)}
                </Text>
              </View>
            ))
          )}
        </View>

        <Pressable style={profileStyles.outline} onPress={() => router.back()} disabled={busy}>
          <Text style={profileStyles.outlineText}>Close</Text>
        </Pressable>
      </ScrollView>

      <Modal visible={Boolean(returnModal)} animationType="slide" transparent onRequestClose={() => setReturnModal(null)}>
        <Pressable style={styles.modalBackdrop} onPress={() => !busy && setReturnModal(null)}>
          <Pressable style={styles.modalInner} onPress={() => {}}>
            <Text style={profileStyles.modalTitle}>Return to store</Text>
            <Text style={profileStyles.modalSub}>Brief reason (shown to pharmacy staff).</Text>
            <TextInput
              style={profileStyles.input}
              value={returnReason}
              onChangeText={setReturnReason}
              placeholder="e.g. Customer not available"
              multiline
            />
            <View style={profileStyles.modalRow}>
              <Pressable
                style={[profileStyles.modalBtn, profileStyles.modalGhost]}
                onPress={() => setReturnModal(null)}
                disabled={busy}>
                <Text style={profileStyles.outlineText}>Cancel</Text>
              </Pressable>
              <Pressable style={[profileStyles.modalBtn, profileStyles.primary]} onPress={() => void confirmReturn()} disabled={busy}>
                {busy ? <ActivityIndicator color="#fff" /> : <Text style={profileStyles.primaryText}>Submit</Text>}
              </Pressable>
            </View>
          </Pressable>
        </Pressable>
      </Modal>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  pad: { paddingHorizontal: 16 },
  centered: { flex: 1, justifyContent: 'center', alignItems: 'center', padding: 24 },
  body: { fontSize: 16, color: Theme.gray900, fontWeight: '600' },
  bodyMuted: { fontSize: 14, color: Theme.gray600, marginTop: 4 },
  amount: { fontSize: 18, fontWeight: '800', color: Theme.secondaryDark },
  actionBtn: {
    backgroundColor: Theme.accentBlue,
    paddingVertical: 14,
    borderRadius: 12,
    alignItems: 'center',
    marginBottom: 10,
  },
  actionBtnDisabled: { opacity: 0.6 },
  actionBtnText: { color: Theme.white, fontWeight: '800', fontSize: 16 },
  lineRow: { marginBottom: 12, paddingBottom: 12, borderBottomWidth: 1, borderBottomColor: Theme.gray100 },
  lineName: { fontSize: 15, fontWeight: '700', color: Theme.gray900 },
  lineMeta: { marginTop: 4, fontSize: 14, color: Theme.gray600 },
  modalBackdrop: {
    flex: 1,
    backgroundColor: 'rgba(15,23,42,0.4)',
    justifyContent: 'flex-end',
  },
  modalInner: {
    backgroundColor: Theme.white,
    borderTopLeftRadius: 18,
    borderTopRightRadius: 18,
    padding: 20,
  },
});
