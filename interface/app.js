const Wait = (ms) => new Promise(resolve => setTimeout(resolve, ms));

const app = Vue.createApp({
    data() {
        return {
            tasks: {}
        }
    },
    methods: {
        async addTask(name, label, duration) {
            // Check is have required key
            if (!name) return;
            if (!duration) return;

            // Check duplicate
            if (this.tasks[name]) return;

            // Add task
            this.tasks[name] = {
                name,
                label,
                duration
            };

            // Wait task finish
            await Wait(duration);

            // Remove tasks
            delete this.tasks[name];
        },
        removeTask(name) {
            delete this.tasks[name];
        }
    },
}).mount('.wrapper');

window.addEventListener('message', ({ data }) => {
    if (data.action === 'play') {
        app.addTask(data.name, data.label, data.duration);
    } else if (data.action === 'stop') {
        app.removeTask(data.name)
    }
});