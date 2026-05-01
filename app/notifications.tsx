import React, { useCallback, useState } from 'react';
import {
  ActivityIndicator,
  FlatList,
  RefreshControl,
  StyleSheet,
  Text,
  View,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { useFocusEffect } from '@react-navigation/native';
import { Redirect } from 'expo-router';

import { profileStyles } from '@/constants/profileScreenStyles';
import { Theme } from '@/constants/theme';
import { useAuth } from '@/context/AuthContext';
import { HREF_AUTH_LOGIN } from '@/lib/navigation';
import { getMyNotifications, type MyNotificationItem } from '@/services/notifications';

function formatWhen(iso: string | null | undefined): string {
  if (!iso) return '';
  const d = new Date(iso);
  if (Number.isNaN(d.getTime())) return iso;
  return d.toLocaleString(undefined, { dateStyle: 'medium', timeStyle: 'short' });
}

export default function NotificationsScreen() {
  const { token, loading: authLoading, isAuthenticated } = useAuth();
  const [items, setItems] = useState<MyNotificationItem[]>([]);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const load = useCallback(async () => {
    if (!token) return;
    setError(null);
    try {
      const res = await getMyNotifications();
      setItems(res.items ?? []);
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Could not load notifications');
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

  if (authLoading) {
    return (
      <SafeAreaView style={profileStyles.safe} edges={['left', 'right', 'bottom']}>
        <View style={styles.centered}>
          <ActivityIndicator size="large" color={Theme.primary} />
        </View>
      </SafeAreaView>
    );
  }

  if (!isAuthenticated) {
    return <Redirect href={HREF_AUTH_LOGIN} />;
  }

  if (loading && !refreshing) {
    return (
      <SafeAreaView style={profileStyles.safe} edges={['left', 'right', 'bottom']}>
        <View style={styles.centered}>
          <ActivityIndicator size="large" color={Theme.primary} />
        </View>
      </SafeAreaView>
    );
  }

  return (
    <SafeAreaView style={[profileStyles.safe, styles.pad]} edges={['left', 'right', 'bottom']}>
      <FlatList
        data={items}
        keyExtractor={(item) => item.id}
        ListHeaderComponent={
          <>
            <Text style={profileStyles.sub}>Showing your latest 30 notifications.</Text>
            {error ? <Text style={profileStyles.empty}>{error}</Text> : null}
          </>
        }
        refreshControl={<RefreshControl refreshing={refreshing} onRefresh={onRefresh} tintColor={Theme.primary} />}
        contentContainerStyle={items.length === 0 ? styles.emptyList : undefined}
        ListEmptyComponent={
          !error ? (
            <Text style={profileStyles.msg}>No notifications yet. Pull to refresh.</Text>
          ) : null
        }
        renderItem={({ item }) => (
          <View style={styles.card}>
            <Text style={styles.title}>{item.title}</Text>
            {item.body ? <Text style={styles.body}>{item.body}</Text> : null}
            <Text style={styles.meta}>
              {formatWhen(item.sent_at ?? item.created_at)}
              {item.send_status ? ` · ${item.send_status}` : ''}
            </Text>
          </View>
        )}
      />
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  pad: { paddingHorizontal: 16, flex: 1 },
  centered: { flex: 1, justifyContent: 'center', alignItems: 'center', padding: 24 },
  emptyList: { flexGrow: 1 },
  card: {
    backgroundColor: Theme.white,
    borderRadius: 12,
    padding: 14,
    marginBottom: 12,
    borderWidth: 1,
    borderColor: Theme.gray100,
  },
  title: { fontSize: 16, fontWeight: '700', color: Theme.gray900 },
  body: { marginTop: 6, fontSize: 14, color: Theme.gray700, lineHeight: 20 },
  meta: { marginTop: 8, fontSize: 12, color: Theme.gray500 },
});
