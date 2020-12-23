export default {
    actions: {
        async SwitchListGet(ctx) {
            const res = await fetch('/api/switch/switch-list')
            const list = await res.json()
            ctx.commit('GetList', list)
        }
    },
    mutations: {
        GetList(state, data) {
            state.SwithList = data
        }
    },
    state: {
        SwithList: []
    },
    getters: {
        SwitchList(state) {
            return state.SwithList
        }
    }
}