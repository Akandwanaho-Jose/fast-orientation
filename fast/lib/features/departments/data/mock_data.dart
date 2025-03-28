import 'package:fast/features/departments/models/department.dart';
import 'package:fast/features/departments/models/program.dart';
import 'package:fast/features/departments/models/course.dart';

final List<Department> mockDepartments = [
  Department(
    id: '1',
    name: 'Electrical and Electronics Engineering',
    description:
        'The Department of Electrical and Electronics Engineering focuses on cutting-edge research and education in electrical systems, electronics, and related technologies.',
    imageUrl: 'assets/images/eee_department.jpg',
    programs: [
      Program(
        name: 'Bachelor of Electrical and Electronics Engineering',
        durationYears: 4,
        yearCourses: [
          YearCourses(
            year: 1,
            courses: [
              Course(
                code: 'EEE101',
                name: 'Introduction to Electrical Engineering',
                description:
                    'This foundational course provides an overview of the principles and concepts of electrical engineering. Topics include:\n- Electric circuits and networks\n- Electromagnetism and electronics\n- Energy systems and conversion\n- Signal processing and communication\nThrough lectures, labs, and assignments, students will gain a solid understanding of electrical engineering fundamentals and develop problem-solving skills to analyze and design electrical systems.',
                credits: 3,
              ),
              Course(
                code: 'EEE102',
                name: 'Mathematics for Engineers I',
                description:
                    'This course introduces essential mathematical tools for engineering applications. Topics include:\n- Calculus and differential equations\n- Linear algebra and matrices\n- Vector analysis\n- Probability and statistics\nThrough problem sets and practical examples, students will develop the mathematical skills necessary for solving engineering problems.',
                credits: 4,
              ),
              Course(
                code: 'EEE103',
                name: 'Physics for Engineers',
                description:
                    'This course explores the physical principles underlying engineering applications. Topics include:\n- Mechanics and motion\n- Thermodynamics and heat transfer\n- Electromagnetism\n- Waves and optics\nThrough theoretical lessons and hands-on experiments, students will learn to apply physics concepts to engineering challenges.',
                credits: 3,
              ),
            ],
          ),
          YearCourses(
            year: 2,
            courses: [
              Course(
                code: 'EEE201',
                name: 'Circuit Theory',
                description:
                    'This course delves into the analysis and design of electrical circuits. Topics include:\n- AC and DC circuit analysis\n- Network theorems (Thevenin, Norton)\n- Filters and resonance\n- Transient and steady-state responses\nThrough simulations and lab work, students will develop skills to analyze and design complex electrical circuits.',
                credits: 4,
              ),
              Course(
                code: 'EEE202',
                name: 'Electronics I',
                description:
                    'This course introduces the fundamentals of electronic devices and circuits. Topics include:\n- Diodes and their applications\n- Transistors (BJT and MOSFET)\n- Amplifiers and oscillators\n- Basic digital electronics\nThrough lectures and practical labs, students will learn to design and analyze electronic circuits.',
                credits: 3,
              ),
              Course(
                code: 'EEE203',
                name: 'Mathematics for Engineers II',
                description:
                    'This course builds on Mathematics for Engineers I, focusing on advanced mathematical techniques. Topics include:\n- Fourier series and transforms\n- Laplace transforms\n- Complex analysis\n- Numerical methods\nThrough applied problems, students will enhance their ability to solve advanced engineering problems.',
                credits: 4,
              ),
            ],
          ),
          YearCourses(
            year: 3,
            courses: [
              Course(
                code: 'EEE301',
                name: 'Control Systems',
                description:
                    'This course covers the principles of control systems in engineering. Topics include:\n- Feedback and stability analysis\n- Transfer functions and block diagrams\n- PID controllers\n- State-space representation\nThrough simulations and projects, students will learn to design and analyze control systems for various applications.',
                credits: 4,
              ),
              Course(
                code: 'EEE302',
                name: 'Power Systems',
                description:
                    'This course introduces the fundamentals of power generation and distribution. Topics include:\n- Power generation and transmission\n- Load flow analysis\n- Fault analysis and protection\n- Renewable energy integration\nThrough case studies and simulations, students will gain insights into the operation and management of power systems.',
                credits: 3,
              ),
              Course(
                code: 'EEE303',
                name: 'Microprocessors',
                description:
                    'This course explores the architecture and programming of microprocessors. Topics include:\n- Microprocessor architecture (e.g., 8085, 8086)\n- Assembly language programming\n- Interfacing with peripherals\n- Embedded systems basics\nThrough hands-on projects, students will learn to program and interface microprocessors for real-world applications.',
                credits: 3,
              ),
            ],
          ),
          YearCourses(
            year: 4,
            courses: [
              Course(
                code: 'EEE401',
                name: 'Renewable Energy Systems',
                description:
                    'This course focuses on sustainable energy technologies. Topics include:\n- Solar energy systems\n- Wind energy systems\n- Hydroelectric power\n- Energy storage and grid integration\nThrough projects and case studies, students will explore the design and implementation of renewable energy solutions.',
                credits: 4,
              ),
              Course(
                code: 'EEE402',
                name: 'Final Year Project',
                description:
                    'This capstone course allows students to apply their knowledge to a real-world engineering problem. Topics include:\n- Project planning and management\n- Research and design methodologies\n- Prototyping and testing\n- Technical report writing\nThrough independent work and mentorship, students will design and implement an innovative electrical engineering solution.',
                credits: 6,
              ),
              Course(
                code: 'EEE403',
                name: 'Engineering Management',
                description:
                    'This course covers the principles of managing engineering projects and teams. Topics include:\n- Project management methodologies\n- Engineering ethics\n- Leadership and teamwork\n- Risk management\nThrough case studies and group activities, students will develop skills to lead and manage engineering projects effectively.',
                credits: 3,
              ),
            ],
          ),
        ],
      ),
    ],
  ),
  Department(
    id: '2',
    name: 'Petroleum Engineering',
    description:
        'The Department of Petroleum Engineering specializes in the exploration, extraction, and production of oil and gas resources.',
    imageUrl: 'assets/images/petroleum_department.jpg',
    programs: [
      Program(
        name: 'Bachelor of Petroleum Engineering',
        durationYears: 4,
        yearCourses: [
          YearCourses(
            year: 1,
            courses: [
              Course(
                code: 'PET101',
                name: 'Introduction to Petroleum Engineering',
                description:
                    'This foundational course provides an overview of the petroleum industry and engineering principles. Topics include:\n- History of the petroleum industry\n- Exploration and drilling techniques\n- Reservoir fundamentals\n- Production processes\nThrough lectures and case studies, students will gain a broad understanding of petroleum engineering and its role in energy production.',
                credits: 3,
              ),
              Course(
                code: 'PET102',
                name: 'Geology for Petroleum Engineers',
                description:
                    'This course introduces geological concepts relevant to oil and gas exploration. Topics include:\n- Rock types and formations\n- Sedimentary basins\n- Structural geology\n- Petroleum traps and reservoirs\nThrough field studies and lab work, students will learn to analyze geological data for petroleum exploration.',
                credits: 4,
              ),
              Course(
                code: 'PET103',
                name: 'Mathematics for Engineers I',
                description:
                    'This course introduces essential mathematical tools for petroleum engineering applications. Topics include:\n- Calculus and differential equations\n- Linear algebra and matrices\n- Vector analysis\n- Probability and statistics\nThrough problem sets and practical examples, students will develop the mathematical skills necessary for solving engineering problems.',
                credits: 4,
              ),
            ],
          ),
          YearCourses(
            year: 2,
            courses: [
              Course(
                code: 'PET201',
                name: 'Drilling Engineering',
                description:
                    'This course covers the principles and techniques of drilling for oil and gas. Topics include:\n- Drilling rig components\n- Drill bit design and selection\n- Drilling fluids and circulation\n- Well control and safety\nThrough simulations and case studies, students will learn to design and manage drilling operations.',
                credits: 4,
              ),
              Course(
                code: 'PET202',
                name: 'Reservoir Engineering I',
                description:
                    'This course introduces the fundamentals of reservoir engineering. Topics include:\n- Reservoir rock and fluid properties\n- Fluid flow in porous media\n- Material balance equations\n- Reservoir performance analysis\nThrough practical exercises, students will learn to evaluate and manage petroleum reservoirs.',
                credits: 3,
              ),
              Course(
                code: 'PET203',
                name: 'Petroleum Chemistry',
                description:
                    'This course explores the chemical properties of petroleum and its derivatives. Topics include:\n- Hydrocarbon chemistry\n- Crude oil composition\n- Refining processes\n- Petrochemical products\nThrough lab experiments and analysis, students will understand the chemical basis of petroleum engineering.',
                credits: 3,
              ),
            ],
          ),
          YearCourses(
            year: 3,
            courses: [
              Course(
                code: 'PET301',
                name: 'Production Engineering',
                description:
                    'This course focuses on optimizing oil and gas production from reservoirs. Topics include:\n- Well completion techniques\n- Artificial lift systems\n- Production optimization\n- Surface facilities design\nThrough simulations and projects, students will learn to maximize production efficiency.',
                credits: 4,
              ),
              Course(
                code: 'PET302',
                name: 'Reservoir Engineering II',
                description:
                    'This course builds on Reservoir Engineering I, focusing on advanced techniques. Topics include:\n- Reservoir simulation and modeling\n- Enhanced oil recovery methods\n- Decline curve analysis\n- Reservoir management strategies\nThrough advanced simulations, students will develop skills to manage complex reservoirs.',
                credits: 4,
              ),
              Course(
                code: 'PET303',
                name: 'Petroleum Economics',
                description:
                    'This course covers economic principles in the petroleum industry. Topics include:\n- Economic evaluation of projects\n- Risk and uncertainty analysis\n- Oil and gas pricing\n- Fiscal systems and contracts\nThrough case studies, students will learn to make informed economic decisions in petroleum projects.',
                credits: 3,
              ),
            ],
          ),
          YearCourses(
            year: 4,
            courses: [
              Course(
                code: 'PET401',
                name: 'Enhanced Oil Recovery',
                description:
                    'This course explores techniques to improve oil recovery from reservoirs. Topics include:\n- Thermal recovery methods\n- Chemical flooding\n- Gas injection techniques\n- Microbial enhanced oil recovery\nThrough projects and simulations, students will learn to design and implement enhanced oil recovery strategies.',
                credits: 4,
              ),
              Course(
                code: 'PET402',
                name: 'Final Year Project',
                description:
                    'This capstone course allows students to apply their knowledge to a real-world petroleum engineering problem. Topics include:\n- Project planning and management\n- Research and design methodologies\n- Prototyping and testing\n- Technical report writing\nThrough independent work and mentorship, students will design and implement an innovative petroleum engineering solution.',
                credits: 6,
              ),
              Course(
                code: 'PET403',
                name: 'Health, Safety, and Environment in Petroleum Industry',
                description:
                    'This course covers safety and environmental considerations in petroleum operations. Topics include:\n- Safety regulations and standards\n- Environmental impact assessment\n- Hazard identification and risk management\n- Sustainable practices\nThrough case studies and group activities, students will learn to ensure safe and environmentally responsible operations.',
                credits: 3,
              ),
            ],
          ),
        ],
      ),
    ],
  ),
  Department(
    id: '3',
    name: 'Civil Engineering',
    description:
        'The Department of Civil Engineering focuses on the design, construction, and maintenance of infrastructure projects.',
    imageUrl: 'assets/images/civil_department.jpg',
    programs: [
      Program(
        name: 'Bachelor of Civil Engineering',
        durationYears: 4,
        yearCourses: [
          YearCourses(
            year: 1,
            courses: [
              Course(
                code: 'CIV101',
                name: 'Introduction to Civil Engineering',
                description:
                    'This foundational course provides an overview of civil engineering principles and practices. Topics include:\n- Structural design basics\n- Construction materials\n- Surveying and mapping\n- Infrastructure planning\nThrough lectures and site visits, students will gain a broad understanding of civil engineering and its impact on society.',
                credits: 3,
              ),
              Course(
                code: 'CIV102',
                name: 'Engineering Drawing',
                description:
                    'This course introduces the fundamentals of technical drawing for civil engineering projects. Topics include:\n- Orthographic projections\n- Isometric drawings\n- Blueprint reading\n- CAD software basics\nThrough hands-on exercises, students will learn to create and interpret engineering drawings.',
                credits: 3,
              ),
              Course(
                code: 'CIV103',
                name: 'Mathematics for Engineers I',
                description:
                    'This course introduces essential mathematical tools for civil engineering applications. Topics include:\n- Calculus and differential equations\n- Linear algebra and matrices\n- Vector analysis\n- Probability and statistics\nThrough problem sets and practical examples, students will develop the mathematical skills necessary for solving engineering problems.',
                credits: 4,
              ),
            ],
          ),
          YearCourses(
            year: 2,
            courses: [
              Course(
                code: 'CIV201',
                name: 'Structural Analysis I',
                description:
                    'This course covers the analysis of structures under various loads. Topics include:\n- Beams and frames\n- Trusses and arches\n- Shear and moment diagrams\n- Deflection analysis\nThrough theoretical lessons and software tools, students will learn to analyze structural behavior.',
                credits: 4,
              ),
              Course(
                code: 'CIV202',
                name: 'Fluid Mechanics',
                description:
                    'This course explores the behavior of fluids in civil engineering applications. Topics include:\n- Fluid properties and statics\n- Fluid dynamics and flow\n- Pipe flow and open channels\n- Hydraulic systems\nThrough experiments and simulations, students will learn to design and analyze fluid systems.',
                credits: 3,
              ),
              Course(
                code: 'CIV203',
                name: 'Surveying',
                description:
                    'This course introduces techniques for land surveying and mapping. Topics include:\n- Leveling and contouring\n- Theodolite and total station\n- GPS and remote sensing\n- Topographic surveys\nThrough field work and practical exercises, students will learn to conduct accurate surveys.',
                credits: 3,
              ),
            ],
          ),
          YearCourses(
            year: 3,
            courses: [
              Course(
                code: 'CIV301',
                name: 'Structural Analysis II',
                description:
                    'This course builds on Structural Analysis I, focusing on advanced techniques. Topics include:\n- Indeterminate structures\n- Influence lines\n- Matrix methods\n- Finite element analysis\nThrough advanced simulations, students will develop skills to analyze complex structures.',
                credits: 4,
              ),
              Course(
                code: 'CIV302',
                name: 'Geotechnical Engineering',
                description:
                    'This course covers the principles of soil mechanics and foundation design. Topics include:\n- Soil properties and classification\n- Shear strength and consolidation\n- Foundation design\n- Slope stability\nThrough lab tests and projects, students will learn to design safe and stable foundations.',
                credits: 4,
              ),
              Course(
                code: 'CIV303',
                name: 'Transportation Engineering',
                description:
                    'This course focuses on the design and analysis of transportation systems. Topics include:\n- Highway design and alignment\n- Traffic flow and capacity\n- Pavement design\n- Transportation planning\nThrough case studies and design projects, students will learn to develop efficient transportation infrastructure.',
                credits: 3,
              ),
            ],
          ),
          YearCourses(
            year: 4,
            courses: [
              Course(
                code: 'CIV401',
                name: 'Water Resources Engineering',
                description:
                    'This course covers the design and management of water-related infrastructure. Topics include:\n- Hydrology and water cycle\n- Water supply systems\n- Irrigation and drainage\n- Flood control\nThrough projects and simulations, students will learn to manage water resources effectively.',
                credits: 4,
              ),
              Course(
                code: 'CIV402',
                name: 'Final Year Project',
                description:
                    'This capstone course allows students to apply their knowledge to a real-world civil engineering problem. Topics include:\n- Project planning and management\n- Research and design methodologies\n- Prototyping and testing\n- Technical report writing\nThrough independent work and mentorship, students will design and implement an innovative civil engineering solution.',
                credits: 6,
              ),
              Course(
                code: 'CIV403',
                name: 'Construction Management',
                description:
                    'This course covers the principles of managing construction projects. Topics include:\n- Project scheduling and cost estimation\n- Contract management\n- Quality control and safety\n- Resource management\nThrough case studies and group activities, students will learn to manage construction projects effectively.',
                credits: 3,
              ),
            ],
          ),
        ],
      ),
    ],
  ),
];
