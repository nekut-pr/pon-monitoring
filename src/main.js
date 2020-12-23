import Vue from 'vue'
import App from './App.vue'
import store from './store'
import VueRouter from 'vue-router'

import VueSidebarMenu from 'vue-sidebar-menu'
import 'vue-sidebar-menu/dist/vue-sidebar-menu.css'

import 'bootstrap/dist/css/bootstrap.css'
import 'bootstrap-vue/dist/bootstrap-vue.css'

// import AmCharts from 'amcharts3'
// import AmSerial from 'amcharts3/amcharts/serial'
import { TablePlugin } from 'bootstrap-vue'
import { ModalPlugin } from 'bootstrap-vue'
import { ButtonPlugin } from 'bootstrap-vue'
import { FormInputPlugin } from 'bootstrap-vue'
import { FormTextareaPlugin } from 'bootstrap-vue'
import { FormSelectPlugin } from 'bootstrap-vue'
import { CollapsePlugin } from 'bootstrap-vue'

import ChoiceSwitch from '@/components/OLT/ChoiceSwitch.vue'
import Dashboard from '@/components/Dashboard.vue'
import OnuSwitch from '@/components/OLT/OnuSwitch.vue'
import SwitchAdd from '@/components/OLT/SwitchAdd.vue'

Vue.use(TablePlugin)
Vue.use(ModalPlugin)
Vue.use(ButtonPlugin)
Vue.use(FormInputPlugin)
Vue.use(FormTextareaPlugin)
Vue.use(FormSelectPlugin)
Vue.use(CollapsePlugin)

// Vue.use(AmCharts)
// Vue.use(AmSerial)

Vue.use(VueRouter)
Vue.use(VueSidebarMenu)

const router = new VueRouter({
  mode: 'history',
  routes: [
    {
      path: '/',
      name: 'Dashboard',
      component: Dashboard
    },
    {
      path: '/switch',
      component: ChoiceSwitch,
    },
    {
      path: '/switch/:id',
      component: OnuSwitch,
    },
    {
      path: '/addolt',
      component: SwitchAdd,
    },
  ]
})


new Vue({
  el: '#app',
  store,
  router,
  render: h => h(App)
})
