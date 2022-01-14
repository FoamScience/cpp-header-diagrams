namespace Foam
{
    class someClass
    :
		public scoped::parent,
		public justParent,
        public scoped::templateParent<1, double>,
        public justTemplateParent<1, double>
    {
    public:
		static Variable st_;
        Member public_m;
		virtual void method(const double&, const int& a) = 0;
		static void anotherMethod(const double&, const int& a);
		template<int N>
		Member<N> public_t;
		template<int N>
		static Cool anotherOne;
        template<class T>
		void templateMethod(const T&, const int& a);
        someClass(int n, Vector v);
    protected:
        SomeVar v_;
        AnotherVar<double> tv_;
    };
    
    template<int N, class T>
    class someTemplateClass
    :
        public parent,
        public templateParent<N, T>
    {
    public:
        Member public_m;
		template<class T> static void memberMethod();
    protected:
        SomeVar k_;
        AnotherVar<T> l_;
        AnotherVar<double> kl_;
    };
}
