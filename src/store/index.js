import Vue from 'vue'
import Vuex from 'vuex'
import createCache from 'vuex-cache';

Vue.use(Vuex)

import GetSwitchList from './modules/SwitchList'
import ModalEdit from './modules/ModalEdit'

export default new Vuex.Store({
    plugins: [createCache()],
    modules: {
        ModalEdit,
        GetSwitchList
    },
})