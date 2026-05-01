import React, { useEffect } from 'react';
import FontAwesome from '@expo/vector-icons/FontAwesome';
import { Redirect, Tabs, useRouter } from 'expo-router';
import { Pressable } from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';

import { useClientOnlyValue } from '@/components/useClientOnlyValue';
import { useAuth } from '@/context/AuthContext';
import { Theme } from '@/constants/theme';
import { HREF_AUTH_LOGIN, HREF_NOTIFICATIONS } from '@/lib/navigation';

function TabBarIcon(props: { name: React.ComponentProps<typeof FontAwesome>['name']; color: string }) {
  return <FontAwesome size={22} style={{ marginBottom: -1 }} {...props} />;
}

function NotificationHeaderButton() {
  const router = useRouter();
  return (
    <Pressable
      onPress={() => router.push(HREF_NOTIFICATIONS)}
      hitSlop={{ top: 12, bottom: 12, left: 12, right: 12 }}
      style={{ marginRight: 8, padding: 4 }}>
      <FontAwesome name="bell-o" size={22} color={Theme.gray900} />
    </Pressable>
  );
}

/**
 * Signed-in shell: assigned deliveries and profile (same tab chrome as customer app).
 */
export default function DeliveryMainLayout() {
  const { loading, isAuthenticated } = useAuth();
  const insets = useSafeAreaInsets();
  const router = useRouter();

  const tabBarBottomPad = 8 + insets.bottom;
  const tabBarHeight = 60 + insets.bottom;

  useEffect(() => {
    if (!loading && !isAuthenticated) {
      router.replace(HREF_AUTH_LOGIN);
    }
  }, [loading, isAuthenticated, router]);

  if (loading) {
    return null;
  }

  if (!isAuthenticated) {
    return <Redirect href={HREF_AUTH_LOGIN} />;
  }

  return (
    <Tabs
      screenOptions={{
        tabBarActiveTintColor: Theme.primary,
        tabBarInactiveTintColor: Theme.gray400,
        tabBarLabelStyle: { fontSize: 11, fontWeight: '700', marginBottom: 2 },
        tabBarStyle: {
          backgroundColor: Theme.white,
          borderTopColor: Theme.gray200,
          height: tabBarHeight,
          paddingBottom: tabBarBottomPad,
          paddingTop: 6,
        },
        headerShown: useClientOnlyValue(false, true),
        headerStyle: {
          backgroundColor: Theme.white,
          elevation: 0,
          shadowOpacity: 0,
          borderBottomWidth: 1,
          borderBottomColor: Theme.gray100,
        },
        headerTitleStyle: {
          fontFamily: 'Inter_600SemiBold',
          fontWeight: '700',
          fontSize: 18,
          color: Theme.gray900,
        },
        headerRight: () => <NotificationHeaderButton />,
      }}>
      <Tabs.Screen
        name="deliveries"
        options={{
          title: 'Deliveries',
          tabBarLabel: 'Deliveries',
          tabBarIcon: ({ color }) => <TabBarIcon name="truck" color={color} />,
        }}
      />
      <Tabs.Screen
        name="history"
        options={{
          title: 'History',
          tabBarLabel: 'History',
          tabBarIcon: ({ color }) => <TabBarIcon name="history" color={color} />,
        }}
      />
      <Tabs.Screen
        name="profile"
        options={{
          title: 'Profile',
          tabBarIcon: ({ color }) => <TabBarIcon name="user-circle" color={color} />,
        }}
      />
    </Tabs>
  );
}
