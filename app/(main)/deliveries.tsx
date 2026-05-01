import React, { useCallback, useState } from 'react';
import {
  ActivityIndicator,
  FlatList,
  Pressable,
  RefreshControl,
  StyleSheet,
  Text,
  View,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { useFocusEffect } from '@react-navigation/native';
import { router } from 'expo-router';

import { profileStyles } from '@/constants/profileScreenStyles';
import { Theme } from '@/constants/theme';
import { useAuth } from '@/context/AuthContext';
import { hrefOrderDetail } from '@/lib/navigation';
import { formatOrderStatusLabel } from '@/lib/orderLifecycle';
import { getAssignedOrders, type OrderRow } from '@/services/orders';

function formatAmount(v: string | number): string {
  const n = typeof v === 'string' ? parseFloat(v) : v;
  if (Number.isNaN(n)) return String(v);
  return `₹${n.toFixed(0)}`;
}

/**
 * Lists orders assigned to the signed-in delivery agent via GET /api/v1/orders (scoped server-side).
 */
export default function AssignedDeliveriesScreen() {
  const { token } = useAuth();
  const [items, setItems] = useState<OrderRow[]>([]);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const load = useCallback(async () => {
    if (!token) return;
    setError(null);
    try {
      const res = await getAssignedOrders({ limit: 50, offset: 0, delivery_list_scope: 'active' });
      setItems(res.items ?? []);
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Could not load deliveries');
      setItems([]);
    } finally {
      setLoading(false);
      setRefreshing(false);
    }
  }, [token]);

  useFocusEffect(
    useCallback(() => {
      setLoading(true);
      void load();
    }, [load]),
  );

  const onRefresh = () => {
    setRefreshing(true);
    void load();
  };

  if (loading && !refreshing) {
    return (
      <SafeAreaView style={profileStyles.safe} edges={['left', 'right']}>
        <View style={styles.centered}>
          <ActivityIndicator size="large" color={Theme.primary} />
        </View>
      </SafeAreaView>
    );
  }

  return (
    <SafeAreaView style={[profileStyles.safe, styles.pad]} edges={['left', 'right']}>
      <FlatList
        data={items}
        keyExtractor={(item) => item.id}
        ListHeaderComponent={
          <>
            <Text style={profileStyles.h1}>Assigned deliveries</Text>
            <Text style={profileStyles.sub}>Orders currently assigned to you by the pharmacy.</Text>
            {error ? <Text style={profileStyles.empty}>{error}</Text> : null}
          </>
        }
        refreshControl={<RefreshControl refreshing={refreshing} onRefresh={onRefresh} tintColor={Theme.primary} />}
        contentContainerStyle={items.length === 0 ? styles.emptyList : undefined}
        ListEmptyComponent={
          !error ? (
            <Text style={profileStyles.msg}>No assigned orders right now. Pull to refresh.</Text>
          ) : null
        }
        renderItem={({ item }) => (
          <Pressable
            style={profileStyles.orderCard}
            onPress={() => router.push(hrefOrderDetail(item.id))}
            android_ripple={{ color: Theme.gray200 }}>
            <Text style={profileStyles.orderRef}>{item.order_reference || item.id}</Text>
            <Text style={styles.line}>{item.customer_name || 'Customer'}</Text>
            <Text style={styles.lineMuted}>{item.customer_phone}</Text>
            <Text style={styles.address} numberOfLines={2}>
              {item.delivery_address}
            </Text>
            <Text style={profileStyles.orderStatus}>{formatOrderStatusLabel(item.order_status)}</Text>
            <Text style={profileStyles.orderAmt}>{formatAmount(item.final_amount)}</Text>
            <Text style={styles.tapHint}>Open for details and actions →</Text>
          </Pressable>
        )}
      />
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  pad: { paddingHorizontal: 16 },
  centered: { flex: 1, justifyContent: 'center', alignItems: 'center', padding: 24 },
  line: { marginTop: 4, fontSize: 15, fontWeight: '700', color: Theme.gray800 },
  lineMuted: { marginTop: 2, fontSize: 14, color: Theme.gray600 },
  address: { marginTop: 6, fontSize: 14, color: Theme.gray700, lineHeight: 20 },
  emptyList: { flexGrow: 1 },
  tapHint: { marginTop: 10, fontSize: 13, fontWeight: '700', color: Theme.primary },
});
