export default {
    actions: {},
    mutations: {},
    state: {
        area: [
            { value: 'пос.Октябрьский', text: 'пос.Октябрьский' },
            { value: 'ДЭУ', text: 'ДЭУ' },
            { value: 'ТРЕСТ', text: 'ТРЕСТ' },
            { value: 'с.Липово', text: 'с.Липово' },
            { value: 'Трубная сторона', text: 'Трубная сторона' },
            { value: 'Город', text: 'Город' },
            { value: 'Хрущевка', text: 'Хрущевка' }
        ]
    },
    getters: {
        Area(state) {
            return state.area
        }
    }
}