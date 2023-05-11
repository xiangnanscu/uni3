import { defineComponent, ref } from "vue";

const Kate = defineComponent({
  render() {
    return <h1>hello, Kate!</h1>;
  },
});

const Sam = defineComponent({
  setup() {
    const name = ref("Sam");
    return () => {
      return <h1>hello, {name.value}</h1>;
    };
  },
});

// non-reative
const Tom = () => {
  return <h1>hello, Tom!</h1>;
};

const Kate2 = defineComponent(() => {
  return () => <h1>hello, Kate21</h1>;
});

export { Kate2, Kate, Sam, Tom };
