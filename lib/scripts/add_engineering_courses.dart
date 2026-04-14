import 'package:cloud_firestore/cloud_firestore.dart';

class AddEngineeringCoursesScript {
  static Future<void> addPetroleumCourses() async {
    final firestore = FirebaseFirestore.instance;

    try {
      print('🚀 Adding Petroleum Engineering courses...');
      
      // Year 1
      await firestore.collection('departments').doc('2').collection('programs').doc('BSc').collection('yearCourses').doc('year1').set({
        'year': 1,
        'courses': [
          {'code': 'PEM1101', 'name': 'Fundamentals of Environmental Management', 'description': 'This course surveys the scientific principles of environmental issues and environmental management practices. Fundamental and emerging topics related to air, land and water pollution, water use and management, aquatic ecosystems, energy and climate change, solid waste management, and the global, continental and national regulatory strategies for environmental management are examined.', 'credits': 3},
          {'code': 'EEE1106', 'name': 'Engineering Mathematics I', 'description': 'This course is meant to introduce engineering students to how the mathematics they have learnt prior to this can be applied in engineering. It covers the concept of complex numbers, partial differentiation and its applications, vector algebra and series expansions.', 'credits': 4},
          {'code': 'PEM1102', 'name': 'Applied Physics I', 'description': 'Applied Physics I is a calculus-based general physics course, required for students majoring in engineering or one of the physical sciences. The discussions will focus on the topics of Mechanics, Heat, and Sound.', 'credits': 3},
          {'code': 'PEM1103', 'name': 'Engineering Drawing', 'description': 'One of the best ways to communicate one\'s ideas is through some form of picture or drawing. This is especially true for the engineer. An engineering drawing course focuses on usage of drawing instruments, lettering, construction of geometric shapes, etc.', 'credits': 3},
          {'code': 'PEM1104', 'name': 'Fundamentals of Petroleum Engineering', 'description': 'This course introduces an overview of petroleum engineering and prepares students for advanced courses within a broader petroleum engineering context in subsequent years.', 'credits': 3},
          {'code': 'PEM1105', 'name': 'Applied Biodiversity', 'description': 'Biodiversity is a term that collectively refers to all species of living things both plants and animals. An understanding of the biological variability and variety of a given area is very vital for planning and conservation purposes.', 'credits': 3},
          {'code': 'BCE1104', 'name': 'Information and Communication Technology', 'description': 'This course draws upon the evolution of Information Communication Technologies as a precursor to applications of computers in day-to-day life.', 'credits': 3},
          {'code': 'COM1101', 'name': 'Communication Skills', 'description': 'The course covers material that will develop the students\' understanding of communication both conceptually and practically.', 'credits': 3},
          {'code': 'DVS1106', 'name': 'Introduction to Political Economy', 'description': 'Introduction to Political Economy is a part of the Development Studies Service Course that is offered to all undergraduate students of MUST.', 'credits': 3},
          {'code': 'PEM1201', 'name': 'Physical Geology', 'description': 'This course is designed to introduce petroleum engineering students to the composition and structure of the earth, its rock types and minerals, surface erosional and depositional features.', 'credits': 3},
          {'code': 'EEE1206', 'name': 'Engineering Mathematics II', 'description': 'This course will build on Engineering Mathematics I. This will introduce Beta and Gamma functions and provide a more detailed application of differentiation and integration.', 'credits': 4},
          {'code': 'PEM1202', 'name': 'Applied Physics II', 'description': 'Applied Physics II is a calculus-based introduction to classical electricity and magnetism, including such topics as, electric charge and electric fields, Gauss\'s law, electric potential, capacitance.', 'credits': 3},
          {'code': 'PEM1203', 'name': 'Materials Science and Engineering', 'description': 'This course introduces the subject of materials science to students. It is designed to make the students appreciate the relationship between material processing, material structure, material properties and material performance.', 'credits': 3},
          {'code': 'PEM1204', 'name': 'General Chemistry', 'description': 'Chemistry is the branch of science that deals with the study of matter, its composition, physical and chemical properties and applications.', 'credits': 3},
          {'code': 'PEM1205', 'name': 'Reservoir Thermodynamics and Fluid Properties', 'description': 'This course develops an understanding of mass, energy, heat, work, efficiency, ideal and real thermodynamic cycles and processes that occur in the reservoir.', 'credits': 3},
          {'code': 'DVS1203', 'name': 'Political Economy of Africa and Development', 'description': 'The African continent stands high among the many countries facing development challenges.', 'credits': 3},
          {'code': 'EEE1215', 'name': 'Fundamentals of Computer Programming', 'description': 'This course equips students with the ability to program in an environment where some object oriented principles are followed.', 'credits': 3},
          {'code': 'PEM1301', 'name': 'Workshop Practice I', 'description': 'The content in this module is intended to equip learners with practical skills in safety, mechanical properties of materials, engineering drawing and bench-work activities.', 'credits': 3},
        ],
      });

      // Year 2
      await firestore.collection('departments').doc('2').collection('programs').doc('BSc').collection('yearCourses').doc('year2').set({
        'year': 2,
        'courses': [
          {'code': 'PEM2101', 'name': 'Sedimentology and Stratigraphy', 'description': 'This course covers applications of sedimentology and stratigraphy to petroleum exploration and development.', 'credits': 3},
          {'code': 'PEM2102', 'name': 'Computer Aided Design', 'description': 'This course is mainly a computer applications course. It builds on the concepts learnt by the student from the Engineering Drawing course.', 'credits': 3},
          {'code': 'EEE2103', 'name': 'Engineering Mathematics III', 'description': 'Drawing from the concepts covered in Engineering Mathematics I and II, this course is designed to consolidate and advance analytical techniques.', 'credits': 4},
          {'code': 'PEM2103', 'name': 'Petroleum Geology', 'description': 'This course is prepared to provide students with a background to the petroleum system.', 'credits': 3},
          {'code': 'PEM2104', 'name': 'Geophysics', 'description': 'Oil and Gas exploration involves a range of data used quantitatively to evaluate the hydrocarbon potential of a given location.', 'credits': 4},
          {'code': 'PEM2105', 'name': 'Fluid Mechanics', 'description': 'The course covers basics and applications of fluid mechanics that is, the conservation laws of mass, energy, and momentum balances.', 'credits': 3},
          {'code': 'PEM2106', 'name': 'Workshop practice II', 'description': 'The content in this module is intended to equip learners with practical skills in sheet metal practices like shearing, spinning, forming, joining.', 'credits': 3},
          {'code': 'DVS2105', 'name': 'Political Economy of Uganda', 'description': 'This development studies course is designed to provide a background for a detailed analysis of processes of political and social change in Uganda.', 'credits': 3},
          {'code': 'PEM2201', 'name': 'Drilling Engineering I', 'description': 'The aim of the course is to provide students with a fundamental understanding of petroleum well drilling procedures, its mechanics, and design methodology.', 'credits': 4},
          {'code': 'DVS2201', 'name': 'Citizenry, Professionalism, Globalization and Entrepreneurship', 'description': 'Citizenry, Professionalism, Globalization and entrepreneurship is part of the Development Studies Service Course.', 'credits': 3},
          {'code': 'PEM2202', 'name': 'Petrophysics', 'description': 'This course is designed to introduce students to the characterisation of rock and fluid properties and their interaction.', 'credits': 3},
          {'code': 'PEM2203', 'name': 'Oilfield Chemistry', 'description': 'This course aims at introducing the fundamental principles of oilfield chemistry.', 'credits': 3},
          {'code': 'EEE2215', 'name': 'Engineering Mathematics IV', 'description': 'The last in the series of engineering mathematics, this course gives an in-depth analysis of vectors and matrices.', 'credits': 4},
          {'code': 'PEM2204', 'name': 'Engineered Environmental Systems', 'description': 'Engineered systems where chemical/biochemical reactions play a major role are frequently encountered in environmental engineering.', 'credits': 3},
          {'code': 'PEM2205', 'name': 'Environmental Toxicology', 'description': 'The course gives a background on the nature and sources of potential chemical pollutants from oil and gas development.', 'credits': 3},
          {'code': 'PEM2301', 'name': 'Industrial Training I', 'description': 'This course introduces students to various technological skills in industries and provides on-job training and exposure.', 'credits': 3},
        ],
      });

      // Year 3
      await firestore.collection('departments').doc('2').collection('programs').doc('BSc').collection('yearCourses').doc('year3').set({
        'year': 3,
        'courses': [
          {'code': 'PEM3101', 'name': 'HSE Management in Oil and Gas Industry', 'description': 'This course covers the best practices regarding environment, health and safety which when adequately implemented can reduce negative impacts of petroleum exploration and production.', 'credits': 3},
          {'code': 'PEM3102', 'name': 'Reservoir Engineering I', 'description': 'The course will introduce the student to Darcy\'s Law & its applications and concepts of fluid flow in petroleum reservoirs.', 'credits': 4},
          {'code': 'PEM3103', 'name': 'Well Logging and Integrated Interpretation', 'description': 'This course is a continuation from the earlier course of Petrophysics to introduce students to the acquisition of subsurface formation data through wireline logging.', 'credits': 3},
          {'code': 'PEM3104', 'name': 'Drilling Engineering II', 'description': 'The aim of the course is to provide students with a fundamental understanding of petroleum well drilling procedures, its mechanics, and design methodology.', 'credits': 4},
          {'code': 'PEM3105', 'name': 'Research Methods', 'description': 'This course introduces students to a number of research methods useful for academic and professional investigations of information practices, texts and technologies.', 'credits': 3},
          {'code': 'PEM3106', 'name': 'Procurement, Logistics & Supply Chain Management for Engineers', 'description': 'The status of many industries today, Oil and Gas in particular is defined by how much advantage they have over competitors in the market.', 'credits': 3},
          {'code': 'PEM3107', 'name': 'Process Dynamics and Control', 'description': 'The purpose of this course is to introduce the key concepts in automatic control and instrumentation of process plants.', 'credits': 3},
          {'code': 'PEM3108', 'name': 'Reservoir Characterization and Modelling', 'description': 'The course involves the use of geophysical, geological, petro-physical and engineering data with geo-statistical methods.', 'credits': 3},
          {'code': 'PEM3201', 'name': 'Environmental Control in Petroleum Engineering', 'description': 'The petroleum industry must minimize the environmental impacts of its various operations.', 'credits': 3},
          {'code': 'PEM3202', 'name': 'Reservoir Engineering II', 'description': 'The course is designed to equip students with content of reservoir engineering, which was not offered in the previous course of Reservoir Engineering I.', 'credits': 4},
          {'code': 'PEM3203', 'name': 'Production Engineering I', 'description': 'The aim of this course is to provide familiarization of the principles and applications of various theories and techniques necessary to design, estimate and maximize production performance.', 'credits': 4},
          {'code': 'PEM3204', 'name': 'Electrotechnics and Electronics', 'description': 'The aim of the course is to provide students with a fundamental understanding of the practical and industrial applications of electricity.', 'credits': 3},
          {'code': 'PEM3205', 'name': 'Group Project', 'description': 'The course is an introduction to solving petroleum and natural engineering problems that involves working in a team.', 'credits': 3},
          {'code': 'PEM3206', 'name': 'Pipeline Engineering', 'description': 'Statistically, pipelines are the safest mode of transportation and constitute a major percentage of the means used in transportation of many components of materials.', 'credits': 3},
          {'code': 'PEM3301', 'name': 'Industrial Training II', 'description': 'During their life, students spend much time acquiring knowledge in lecture room with limited exposure to industrial practices.', 'credits': 3},
        ],
      });

      // Year 4
      await firestore.collection('departments').doc('2').collection('programs').doc('BSc').collection('yearCourses').doc('year4').set({
        'year': 4,
        'courses': [
          {'code': 'PEM4101', 'name': 'Petroleum Production Engineering II', 'description': 'The aim of this course is to provide continuation of the principles and applications of various theories and techniques necessary to design, estimate and maximize production performance.', 'credits': 4},
          {'code': 'PEM4102', 'name': 'Petroleum Economics and Management', 'description': 'Petroleum engineers perform technical work to support "business" objectives of the organization they work for.', 'credits': 3},
          {'code': 'PEM4103', 'name': 'Gas Reservoir Engineering', 'description': 'Gas reservoir engineering introduces students to fundamental problem solving in gas reservoir engineering through practical equations and methods.', 'credits': 3},
          {'code': 'PEM4104', 'name': 'Numerical Reservoir Simulation', 'description': 'Basic differential equations governing transport of fluids through porous media will be established.', 'credits': 3},
          {'code': 'PEM4105', 'name': 'Principles of Enhanced Oil Recovery', 'description': 'Enhanced Oil Recovery (EOR) processes are technologies designed to improve recovery of oil from the reservoir after primary and secondary recovery mechanisms.', 'credits': 3},
          {'code': 'PEM4106', 'name': 'Technology of Artificial Lift Methods', 'description': 'Oil reservoirs cannot produce fluids at economical rates unless natural driving mechanisms are present.', 'credits': 3},
          {'code': 'PEM4107', 'name': 'Principles of Modern Well Testing and Interpretation', 'description': 'This course is designed to equip students with detailed understanding of the reservoir engineering principles of well testing.', 'credits': 3},
          {'code': 'PEM4201', 'name': 'Engineering Research Project', 'description': 'The final year project represents the capstone and culmination of your four-year engineering degree.', 'credits': 4},
          {'code': 'PEM4202', 'name': 'Entrepreneurship Development and Business Ethics', 'description': 'This course will introduce students to the skills required in owning and running a business.', 'credits': 3},
          {'code': 'PEM4203', 'name': 'Engineering Ethics', 'description': 'This course is designed to introduce undergraduate engineering students to the concepts, theory and practice of engineering ethics.', 'credits': 3},
          {'code': 'PEM4204', 'name': 'Energy Policy, Planning and Sustainable Development', 'description': 'This course covers scope for policy input, issues, resources, development, Clarifications, Drafting and discussions.', 'credits': 3},
          {'code': 'PEM4205', 'name': 'Petroleum Processing', 'description': 'Crude oil extracted from the ground contains a number of impurities viz., dissolved salts, traces of metals and other inorganic compounds.', 'credits': 3},
        ],
      });

      print('✅ Petroleum Engineering courses added successfully!');
    } catch (e) {
      print('❌ Error: $e');
    }
  }
}