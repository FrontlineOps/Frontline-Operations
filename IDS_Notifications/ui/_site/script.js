//=============================================================================
// #region ACTIONS
//=============================================================================

const NotificationActionTypes = {
    ADD_NOTIFICATION: 'ADD_NOTIFICATION',
    REMOVE_NOTIFICATION: 'REMOVE_NOTIFICATION',
    CLEAR_NOTIFICATIONS: 'CLEAR_NOTIFICATIONS',
    UPDATE_NOTIFICATION: 'UPDATE_NOTIFICATION'
};

const notificationActions = {
    addNotification: (notification) => ({
        type: NotificationActionTypes.ADD_NOTIFICATION,
        payload: {
            id: Date.now() + Math.random(),
            timestamp: Date.now(),
            type: 'info',
            title: 'Notification',
            message: 'Default message',
            duration: 0,
            status: 'showing',
            ...notification
        }
    }),
    removeNotification: (id) => ({
        type: NotificationActionTypes.REMOVE_NOTIFICATION,
        payload: { id }
    }),
    clearNotifications: () => ({
        type: NotificationActionTypes.CLEAR_NOTIFICATIONS
    }),
    updateNotification: (id, updates) => ({
        type: NotificationActionTypes.UPDATE_NOTIFICATION,
        payload: { id, updates }
    })
};

//=============================================================================
// #region REDUCER
//=============================================================================

const notificationInitialState = {
    notifications: [],
    maxNotifications: 5
};

function notificationReducer(state = notificationInitialState, action = {}) {
    switch (action.type) {
        case NotificationActionTypes.ADD_NOTIFICATION: {
            if (!action.payload) return state;
            let newNotifications = [...state.notifications];
            if (newNotifications.length >= state.maxNotifications) {
                newNotifications = newNotifications.slice(1);
            }
            return { ...state, notifications: [...newNotifications, action.payload] };
        }
        case NotificationActionTypes.REMOVE_NOTIFICATION: {
            if (!action.payload || !action.payload.id) return state;
            return {
                ...state,
                notifications: state.notifications.filter(n => n.id !== action.payload.id)
            };
        }
        case NotificationActionTypes.CLEAR_NOTIFICATIONS:
            return { ...state, notifications: [] };
        case NotificationActionTypes.UPDATE_NOTIFICATION: {
            if (!action.payload || !action.payload.id || !action.payload.updates) return state;
            return {
                ...state,
                notifications: state.notifications.map(n =>
                    n.id === action.payload.id ? { ...n, ...action.payload.updates } : n
                )
            };
        }
        default:
            return state;
    }
}

//=============================================================================
// #region STORE
//=============================================================================

class Store {
    constructor(reducer, initialState) {
        this.reducer = reducer;
        this.state = initialState;
        this.listeners = [];
    }

    getState() {
        return this.state;
    }

    dispatch(action) {
        this.state = this.reducer(this.state, action);
        this.listeners.forEach(listener => listener(this.state));
        return action;
    }

    subscribe(listener) {
        this.listeners.push(listener);
        return () => {
            this.listeners = this.listeners.filter(l => l !== listener);
        };
    }
}

const notificationStore = new Store(notificationReducer, notificationInitialState);

//=============================================================================
// #region SELECTORS
//=============================================================================

const notificationSelectors = {
    getNotifications: (state) => state.notifications,
    getMaxNotifications: (state) => state.maxNotifications
};

//=============================================================================
// #region UI COMPONENT
//=============================================================================

class NotificationUI {
    constructor(store) {
        this.store = store;
        this.unsubscribe = null;
        this.container = document.getElementById('notification-container');
        this.renderedNotifications = new Map();
    }

    init() {
        if (!this.container) {
            console.error('Notification container not found');
            return;
        }
        this.unsubscribe = this.store.subscribe((state) => this.render(state));
        this.render(this.store.getState());
    }

    destroy() {
        if (this.unsubscribe) this.unsubscribe();
        this.renderedNotifications.forEach(el => {
            if (el.parentNode) el.parentNode.removeChild(el);
        });
        this.renderedNotifications.clear();
    }

    render(state) {
        const notifications = notificationSelectors.getNotifications(state);

        // Remove notifications no longer present
        const currentIds = new Set(notifications.map(n => n.id));
        for (const [id, el] of this.renderedNotifications.entries()) {
            if (!currentIds.has(id)) {
                if (el.parentNode) el.parentNode.removeChild(el);
                this.renderedNotifications.delete(id);
            }
        }

        // Add or update notifications
        notifications.forEach(notification => {
            if (!notification || !notification.id) return;
            if (!this.renderedNotifications.has(notification.id)) {
                this.createNotificationElement(notification);
            } else {
                this.updateNotificationElement(notification);
            }
        });
    }

    createNotificationElement(notification) {
        const el = document.createElement('div');
        el.className = `notification ${notification.type || 'info'}`;
        el.dataset.id = notification.id;
        el.innerHTML = `
            <div class="notification-header">
                <div class="notification-title">${notification.title || 'Notification'}</div>
            </div>
            <div class="notification-message">${notification.message || 'No message'}</div>
            ${notification.duration > 0 ? '<div class="notification-progress"><div class="notification-progress-bar"></div></div>' : ''}
        `;
        this.container.appendChild(el);
        this.renderedNotifications.set(notification.id, el);
        setTimeout(() => el.classList.add('show'), 10);

        // Set progress bar animation duration
        if (notification.duration > 0) {
            const progressBar = el.querySelector('.notification-progress-bar');
            if (progressBar) {
                progressBar.style.transition = `width ${notification.duration}ms linear`;
                progressBar.style.width = '100%';
                setTimeout(() => {
                    progressBar.style.width = '0%';
                }, 20);
            }

            setTimeout(() => {
                notificationStore.dispatch(notificationActions.updateNotification(notification.id, { status: 'hiding' }));
                setTimeout(() => {
                    notificationStore.dispatch(notificationActions.removeNotification(notification.id));
                }, 300);
            }, notification.duration);
        }
    }

    updateNotificationElement(notification) {
        const el = this.renderedNotifications.get(notification.id);
        if (!el) return;
        if (notification.status === 'hiding') el.classList.add('hide');
    }
}

//=============================================================================
// #region GLOBAL API & EVENT HANDLING
//=============================================================================

let notificationUI = null;
let notificationUIInitialized = false;

function notifyArmaNotificationReady() {
    if (window.parent && window.parent !== window && typeof window.parent.postMessage === "function") {
        window.parent.postMessage({ event: "notifications::ready" }, "*");
    }
    if (typeof A3API !== "undefined" && typeof A3API.SendAlert === "function") {
        A3API.SendAlert(JSON.stringify({ event: "notifications::ready" }));
    }
}

function initializeNotifications() {
    if (notificationUIInitialized) {
        console.log('Notification system already initialized, skipping...');
        return;
    }
    notificationUI = new NotificationUI(notificationStore);
    notificationUI.init();
    notificationUIInitialized = true;
    console.log('Notification system is ready!');
    notifyArmaNotificationReady();
}

// Expose global notification API
const showNotification = (type, title, message, duration) => {
    return notificationStore.dispatch(notificationActions.addNotification({ type, title, message, duration }));
};
const clearAllNotifications = () => {
    return notificationStore.dispatch(notificationActions.clearNotifications());
};

// Listen for global notification events (for Arma/SQF or other scripts)
window.addEventListener('ids:notify', function (e) {
    if (!e || !e.detail) return;
    const { type, title, message, duration } = e.detail;
    showNotification(type, title, message, duration);
});

// Auto-initialize if DOM is already loaded when script executes
if (document.readyState !== 'loading') {
    initializeNotifications();
} else {
    document.addEventListener('DOMContentLoaded', initializeNotifications, { once: true });
}