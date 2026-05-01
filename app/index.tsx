import { Redirect } from 'expo-router';

import { useAuth } from '@/context/AuthContext';
import { HREF_AUTH_LOGIN, HREF_DELIVERIES } from '@/lib/navigation';

/**
 * Cold start: delivery agents go to the deliveries tab when signed in, otherwise sign-in.
 */
export default function Index() {
  const { loading, isAuthenticated } = useAuth();

  if (loading) {
    return null;
  }

  if (!isAuthenticated) {
    return <Redirect href={HREF_AUTH_LOGIN} />;
  }

  return <Redirect href={HREF_DELIVERIES} />;
}
