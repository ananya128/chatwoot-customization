import { frontendURL } from '../../../../helper/URLHelper';

const contacts = accountId => ({
  parentNav: 'contacts',
  routes: [
    'contacts_dashboard_index',
    'contacts_dashboard_segments_index',
    'contacts_dashboard_labels_index',
    'contacts_edit',
    'contacts_edit_segment',
    'contacts_edit_label',
    'contacts_dashboard_active',
  ],
  menuItems: [
    {
      icon: 'contact-card-group',
      label: 'ALL_CONTACTS',
      hasSubMenu: false,
      toState: frontendURL(`accounts/${accountId}/contacts?page=1`),
      toStateName: 'contacts_dashboard_index',
    },
    {
      icon: 'visitor-contacts',
      label: 'ACTIVE',
      hasSubMenu: false,
      toState: frontendURL(`accounts/${accountId}/contacts/active`),
      toStateName: 'contacts_dashboard_active',
    },
  ],
});

export default contacts;
