<template>
<div>
    <table>
        <tr><th>IP Адресс</th><th>Имя</th></tr>
        <router-link 
            v-for="info in SwitchList" 
            :key="info.ip_address" 
            tag="tr" 
            :to="{path:`/switch/${info.ip_address}`}">{{int2ip(info.ip_address)}}<br>
            <small>{{info.model}}</small>
            <td>{{info.name}}</td>
        </router-link>
    </table>
</div>
</template>

<script>
import { mapGetters, mapState } from 'vuex'
export default {
    // computed: {
    //     SwitchList () {
    //         return this.$store.state.SwitchListGet;
    //     }
    // },  
    computed: mapGetters(['SwitchList']), 
 
    // computed: mapState(['SwitchListGet']),
    async mounted() {
        // this.$store.cache.dispatch('SwitchList');
        // this.$store.state.SwitchListGet;
        this.$store.dispatch("SwitchListGet")
        if (this.$store.cache.has('SwitchListGet')) {
            console.log('has cache');
        } else {
            console.log('not has cache');
        }
    },
    methods: {
        int2ip: function (ipInt) {
            return ((ipInt >>> 24) + '.' + (ipInt >> 16 & 255) + '.' + (ipInt >> 8 & 255) + '.' + (ipInt & 255));
        },
    }
}
</script>

<style scoped>
    @import "./style/table.css";
</style>