class coupledSystem
{
protected:

        //- Const access to mesh
        const fvMesh& mesh_;

        //- Phase names
        //  Oreder is important here; in VOF context, alpha phases should appear last
        wordList phaseNames_;

        //- Dictionary for settings
        dictionary dict_;

        //- Pressure field name
        word pName_;

        //- Velocity field name
        word UName_;

        //- Per-Phase fields
        wordList perPhaseFieldNames_;

        //- Phase field names scheme
        word phaseFieldsScheme_;

        //- Used to check if all expected equations were added
        HashTable<bool> addedEquations_;

    // Private Member Functions

        //- Disallow default bitwise copy construct
        coupledSystem(const coupledSystem&);

        //- Disallow default bitwise assignment
        void operator=(const coupledSystem&);


public:

    //- Runtime type information
    //TypeName("coupledSystem");

    //- Type of functions to execute
    using callableType = std::function<void(coupledSystem&)>;

    // Declare run-time constructor selection table
    //declareRunTimeSelectionTable
    //(
    //    autoPtr,
    //    coupledSystem,
    //    phases,
    //    (
    //        const fvMesh& mesh,
    //        const wordList& phaseNames
    //    ),
    //    (mesh, phaseNames)
    //);

    // Constructors

        //- Construct from IOobject
        coupledSystem
        (
            const fvMesh& mesh,
            const wordList& phaseNames
        );

    // Selectors

        //- Return pointer to a new coupledSystem
        static autoPtr<coupledSystem> New
        (
            const fvMesh& mesh,
            const wordList& phaseNames
        );

    //- Destructor
    virtual ~coupledSystem();


    // Member Functions

        //- Solve and retrieve fields
        virtual bool update() = 0;

        //- Insert a scalar equation
        virtual void insertEquation(fvScalarMatrix& eqn) = 0;

        //- Insert a vector equation
        virtual void insertEquation(fvVectorMatrix& eqn) = 0;

        //- Insert a coupling equation as a scalarField
        virtual void insertEquationCoupling
        (
            const word& attachedField,
            const word& coupledField,
            const scalarField& coupling
        ) = 0;

        //- Insert a coupling equation
        virtual void insertEquationCoupling
        (
            const word& attachedField,
            const word& coupledField,
            const fvScalarMatrix& coupling
        ) = 0;

        //- Insert existing vector-to-scalar block system into the matrix
        virtual void insertBlockCoupling
        (
            const word& attachedField,
            const word& coupledField,
            const BlockLduSystem<vector, scalar>& blockSystem
        )  = 0;

        //- Insert existing vector-to-vector block system into the matrix
        virtual void insertBlockCoupling
        (
            const word& attachedField,
            const word& coupledField,
            const BlockLduSystem<vector, vector>& blockSystem
        )  = 0;

        //- Execute a callable on the system
        virtual void execute(callableType& func);
};

template <int nPhases>
class coupledSystemTemplate
:
    public coupledSystem,
    public regIOobject
{

public:

    //- Number of equations (nPhasesFields Equation per phase + p + U)
    constexpr static int nEqns = 4 + nPhaseEquations<nPhases>::value();

    //- Component type of a block element
    using CmptType = VectorN<scalar, nEqns>;

    //- Coupled field type
    using FieldType = GeometricField<CmptType, fvPatchField, volMesh>;

    //- Matrix Coefficient Field type
    using CoeffFieldType = typename fvBlockMatrix<CmptType>::TypeCoeffField;

protected:

    // Protected Member Data

        //- Number of phases as a runTime value
        int runNPhases_;

        //- Coupling field
        FieldType field_;

        //- Underlying coupled matrix
        fvBlockMatrix<CmptType> matrix_;

        //- To store results from solving the equations
        BlockSolverPerformance<CmptType> performance_;

        //- Phase-related Field names
        wordList phaseFieldNames_;

        //- HashTable for indices of 1st component of fields in the system
        HashTable<unsigned> fieldIndex_;

        //- Is this the first run?
        bool firstRun_;

    // Private Member Functions

        //- Disallow default bitwise copy construct
        coupledSystemTemplate(const coupledSystemTemplate&);

        //- Disallow default bitwise assignment
        void operator=(const coupledSystemTemplate&);


public:

    //- Runtime type information
    ClassName(nPhasesToChars<nPhases>::value);

    // Constructors

        //- Construct from IOobject
        coupledSystemTemplate
        (
            const fvMesh& mesh,
            const wordList& phaseNames
        );


    //- Destructor
    virtual ~coupledSystemTemplate();


    // Member Functions

        //- Solve and retrieve fields
        virtual bool update();

        //- Insert a scalar equation
        virtual void insertEquation(fvScalarMatrix& eqn);

        //- Insert a vector equation
        virtual void insertEquation(fvVectorMatrix& eqn);

        //- Insert a coupling equation as a scalarField
        virtual void insertEquationCoupling
        (
            const word& attachedField,
            const word& coupledField,
            const scalarField& coupling
        );

        //- Insert a scalar coupling equation
        virtual void insertEquationCoupling
        (
            const word& attachedField,
            const word& coupledField,
            const fvScalarMatrix& coupling
        );

        //- Insert existing vector-to-scalar block system into the matrix
        virtual void insertBlockCoupling
        (
            const word& attachedField,
            const word& coupledField,
            const BlockLduSystem<vector, scalar>& blockSystem
        );

        //- Insert existing vector-to-vector block system into the matrix
        virtual void insertBlockCoupling
        (
            const word& attachedField,
            const word& coupledField,
            const BlockLduSystem<vector, vector>& blockSystem
        );

        //- Return number of phases a runTime value
        int runNPhases() const
        {
            return runNPhases_;
        }

        //- Access to the matrix
        fvBlockMatrix<CmptType> blockMatrix()
        {
            return matrix_;
        }

        // Const Access to the matrix
        const fvBlockMatrix<CmptType> blockMatrix() const
        {
            return matrix_;
        }

        // Return matrix source
        virtual const Field<CmptType>& source() const
        {
            return matrix_.source();
        }

        // Return matrix source
        virtual Field<CmptType>& source()
        {
            return matrix_.source();
        }

        // Return matrix diagonal
        virtual const CoeffFieldType& diag() const
        {
            return matrix_.diag();
        }

        // Return matrix diagonal
        virtual CoeffFieldType& diag()
        {
            return matrix_.diag();
        }

        // Return matrix upper
        virtual const CoeffFieldType& upper() const
        {
            return matrix_.upper();
        }

        // Return matrix upper
        virtual CoeffFieldType& upper()
        {
            return matrix_.upper();
        }

        // Return matrix lower
        virtual const CoeffFieldType& lower() const
        {
            return matrix_.lower();
        }

        //- Return matrix lower
        virtual CoeffFieldType& lower()
        {
            return matrix_.lower();
        }

        //- Return field indices in the matrix
        HashTable<unsigned, word>& fieldIndex()
        {
            return fieldIndex_;
        }

        //- Return solver performance
        BlockSolverPerformance<CmptType>& performance()
        {
            return performance_;
        }

        //- Not implement writing
        virtual bool writeData(Ostream&) const; // { return false; };
};
