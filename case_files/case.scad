include <BOSL/constants.scad>
include <BOSL/metric_screws.scad>
include <BOSL/shapes.scad>
include <BOSL/transforms.scad>
include <NopSCADlib/lib.scad>

// Epsilon value for offsetting coincident face differences.
E = 0.004;

case_width = 60;
case_length = 85;
case_height = 22;

wall_thickness = 3;
corner_radius = 3;
corner_extension_thickness = wall_thickness * 2;

lid_thickness = 3;
lid_screw_hole_diameter = 3.8;

threaded_insert_hole_diameter = 4.4;
threaded_insert_hole_depth = 7;

usb_screw_hole_diameter = 3.8;

usb_port_hole_height = 10;
usb_port_hole_width = 18;
usb_port_screw_to_midpoint = 14.8;

gcc_connector_diameter = 14;
gcc_connector_length = 28.8;
gcc_connector_centre_to_flat_side = 5;
gcc_connector_slot_clearance = 0.25;
gcc_connector_slot_thickness = 3;
gcc_connector_slot_length = 25;

gcc_connector_stopper_thickness = 5;
gcc_connector_stopper_gap_size = 5;

pico_width = 21;
pico_height = 51;
pico_centre_x = 0.5;
pico_centre_y = wall_thickness / 2;
pico_screw_hole_centre_x_offset = 2;
pico_screw_hole_centre_y_offset = 4.8;
pico_screw_hole_x = (
  pico_centre_x
  + (pico_height / 2)
  - pico_screw_hole_centre_x_offset
);
pico_screw_hole_y = (
  pico_centre_y
  + (pico_width / 2)
  - pico_screw_hole_centre_y_offset
);

pico_mounting_hole_depth = 3;
pico_mounting_hole_diameter = 1.8;
pico_mounting_hole_wall_thickness = 1;

reset_hole_x_offset = 12.33;
reset_hole_y_offset = 7.05;
reset_hole_x = (
  -pico_centre_x
  + (pico_height / 2)
  - reset_hole_x_offset
);
reset_hole_y = (
  pico_centre_y
  + (pico_width / 2)
  - reset_hole_y_offset
);
reset_hole_diameter = 1.6;

/* Begin modules */ 
case();
*lid();
pico_preview();


module case() {
  difference() {
    case_with_corner_extensions();

    // Move to the near end of the case and cut out USB panel mount holes.
    translate([0, -case_length / 2 - E, 0]) {
      usb_panel_mount();
    }

    // Move to the far end of the case and cut out GCC connector hole.
    translate([0, case_length / 2 + E, 0]) {
      gcc_connector_hole();
    }

    // Cut holes for threaded inserts in the centre of the squares created by
    // the outer and inner corner pieces.
    threaded_insert_holes();

    // Cut out reset button hole for Pico.
    pico_reset_hole();
  }

  // Move to the far end of the case and create GCC connector slot.
  translate([0, case_length / 2 + E, 0]) {
    gcc_connector_slot();
  }

  // Create standoffs for the Raspberry Pi Pico.
  pico_standoffs();
}

module case_with_corner_extensions() {
  difference() {
    // Base shape.
    cuboid([
      case_width,
      case_length,
      case_height
    ], fillet=corner_radius, edges=EDGES_Z_ALL);

    // Hollow out the cuboid.
    translate([0, 0, wall_thickness])
      cuboid([
        case_width - wall_thickness * 2,
        case_length - wall_thickness * 2,
        case_height
      ]);
  }

  // Extend corners inwards.
  corner_extensions();
}

module usb_panel_mount() {
  // USB port hole.
  cuboid([
    usb_port_hole_width,
    wall_thickness * 2 + 1,
    usb_port_hole_height
  ]);

  // USB port screw holes.
  xflip_copy() translate([usb_port_screw_to_midpoint, 0, 0]) {
    metric_bolt(
      size=lid_screw_hole_diameter,
      l=wall_thickness + E * 2,
      headtype="countersunk",
      pitch=0,
      orient=ORIENT_YNEG,
      align=V_BACK
    );
  }
}

module gcc_connector_hole() {
  // Create hole in wall for GCC connector.
  difference() {
    ycyl(
      l=wall_thickness + E * 2,
      d=gcc_connector_diameter + gcc_connector_slot_clearance * 2,
      align=V_FWD
    );

    translate([
      0,
      0,
      -(gcc_connector_centre_to_flat_side + gcc_connector_slot_clearance)
    ])
      cuboid([
        gcc_connector_diameter,
        wall_thickness + E * 2,
        gcc_connector_slot_thickness
      ], align=V_DOWN + V_FWD);
  }
}

module gcc_connector_slot() {
  // We again create the interior slot shape but this time in 2D. We then create
  // a shell around this 2D slot shape, and linear extrude it for the length of
  // the slot to create the final 3D exterior slot shape.
  rotate([90])
    linear_extrude(gcc_connector_slot_length) 
      shell2d(gcc_connector_slot_thickness)
        // This circle and square are equivalent to the ycyl and cuboid in
        // gcc_connector_hole().
        difference() {
          circle(d=gcc_connector_diameter + gcc_connector_slot_clearance * 2);
          translate([
            0,
            -(gcc_connector_centre_to_flat_side
              + gcc_connector_slot_clearance
              + gcc_connector_slot_thickness / 2)
          ])
            square([
              gcc_connector_diameter,
              gcc_connector_slot_thickness
            ], center=true);
          }
}

module corner_extensions() {
  // Inner corner blocks for threaded inserts to go into.
  yflip_copy() xflip_copy() translate([
    case_width / 2 - wall_thickness,
    case_length / 2 - wall_thickness,
    case_height / 2
  ])
    // Corner extension thing.
    cuboid(
      [
        corner_extension_thickness,
        corner_extension_thickness,
        case_height - wall_thickness
      ],
      fillet=corner_radius,
      edges=EDGE_FR_LF,
      align=V_DOWN + V_FWD + V_LEFT
    );
}

module threaded_insert_holes() {
  // Place hole for threaded insert at centre point of extended inner corners.
  yflip_copy() xflip_copy() translate([
    (case_width - wall_thickness - corner_extension_thickness) / 2,
    (case_length - wall_thickness - corner_extension_thickness) / 2,
    case_height / 2 + E
  ])
    zcyl(
      d=threaded_insert_hole_diameter,
      l=threaded_insert_hole_depth + E,
      align=V_DOWN
    );
}

module pico_standoffs() {
  yflip_copy(cp=[0, pico_centre_y]) xflip_copy(cp=[pico_centre_x, 0])
    translate([
      pico_screw_hole_x,
      pico_screw_hole_y,
      -case_height / 2 + wall_thickness
    ])
      linear_extrude(pico_mounting_hole_depth)
        shell2d(pico_mounting_hole_wall_thickness)
          circle(d=pico_mounting_hole_diameter);
}

module pico_reset_hole() {
  translate([
    -reset_hole_x,
    reset_hole_y,
    -case_height / 2 + wall_thickness + E
  ])
    zcyl(d=pico_mounting_hole_diameter, l=wall_thickness + E * 2, align=V_DOWN);
}

module lid() {
  lid_z_offset = case_height / 2;

  translate([0, 0, lid_z_offset]) {
    difference() {
      cuboid(
        [case_width, case_length, lid_thickness],
        fillet=corner_radius,
        edges=EDGES_Z_ALL,
        align=V_UP
      );

      // Cut out screw holes in the lid.
      lid_screw_holes();
    }

    // Slot thing that holds GCC connector in place.
    gcc_connector_stopper();
  }
}

module lid_screw_holes() {
  // Place lid screw hole in same place as threaded insert hole.
  yflip_copy() xflip_copy() translate([
    (case_width - wall_thickness - corner_extension_thickness) / 2,
    (case_length - wall_thickness - corner_extension_thickness) / 2,
    lid_thickness + E
  ]) {
    metric_bolt(
      size=lid_screw_hole_diameter,
      l=6,
      headtype="countersunk",
      pitch=0,
      align=V_DOWN
    );
  }
}

module gcc_connector_stopper() {
  gcc_connector_stopper_height = (
    case_height
    - wall_thickness
    - pico_mounting_hole_depth
    - 2.5
  );

  
  translate([
    0,
    (
      case_length / 2
      - gcc_connector_length - 0.5
      - gcc_connector_stopper_thickness / 2
    ),
    0
  ])
    difference() {
      cuboid([
        gcc_connector_diameter,
        gcc_connector_stopper_thickness,
        gcc_connector_stopper_height
      ], align=V_DOWN, fillet=1, edges=EDGES_Y_BOT);

      // Slot/gap for cable/wires coming out of GCC connector.
      hull() {
        translate([0, 0, -case_height / 2])
          ycyl(
            d=gcc_connector_stopper_gap_size,
            l=gcc_connector_stopper_thickness + E
          );
        translate([0, 0, -gcc_connector_stopper_height])
          cuboid([
            gcc_connector_stopper_gap_size,
            gcc_connector_stopper_thickness + E,
            E
          ], align=V_UP);
      }
    }
}

module pico_preview() {
  translate([
    pico_centre_x,
    pico_centre_y,
    -(case_height / 2) + wall_thickness + pico_mounting_hole_depth + 1.6
  ])
    rotate([180, 0]) 
      pcb(RPI_Pico);
}
